#include <thread>
#include <iostream>
#include <fstream>
#include <queue>
#include <vector>
#include <chrono>
#include <mutex>
#include <algorithm>
#include <cmath>
#include <string>
#include <iomanip>
#include <condition_variable>
#include <sstream>

//enums for simplification and readability
enum Priority{high,low}; 
enum Direction{east,west};

class Train{
    public: 
        int train_number;
        Priority priority;
        Direction direction;
        //chrono durations with decisecond periods.
        std::chrono::duration<int , std::ratio<1,10>> loading_time, crossing_time;
        
        //Train class constructor.
        Train(int train__number, char e_or_w, int loading__time, int crossing__time){
            train_number = train__number;
            if (isupper(e_or_w)){ //if uppercase prior = high
                priority = Priority::high;
            }else{
                priority = Priority::low;
            }
            if (e_or_w == 'e' || e_or_w == 'E'){
                direction = Direction::east;
            }else{
                direction = Direction::west;
            }
            loading_time = std::chrono::duration<int , std::ratio<1,10>>(loading__time);
            crossing_time = std::chrono::duration<int , std::ratio<1,10>>(crossing__time);
        }

        //used to repr(std::cout) Train objects for testing purposes.
        friend std::ostream& operator<<(std::ostream& os, const Train& t){
            os << t.train_number<<'/'<<
            static_cast<std::underlying_type<Priority>::type>(t.priority)<<'/'<< 
            static_cast<std::underlying_type<Direction>::type>(t.direction)<<'/'<< 
            t.loading_time.count()<<'/'<< 
            t.crossing_time.count();
            return os;
        }

        /**
         * @brief operator overload automatically used 
         *        in priority queue(min heap) comparasens.
         * 
         * @param lhs Train and rhs Train
         * @return false if lhs is higher priority 
         */
        bool operator<(const Train & rhs)const{
            if (priority ==  rhs.priority){
                if (loading_time == rhs.loading_time){
                    return train_number > rhs.train_number;
                }else{
                    return loading_time > rhs.loading_time;
                }
            }else{
                return !priority == Priority::high;
            }
        }
};

//priority queue for traveling both directions down main track.
std::priority_queue<Train> east_pq;
std::priority_queue<Train> west_pq;

std::mutex pq_mtx; //mutex for either pq i/o operations for dispatcher thread.
std::mutex cout_mutex; //needed to avoid threads race to std::cout

std::mutex dispatch_mutex; //required for std::condition_variable pq_cond.
std::condition_variable pq_cond;

std::mutex begin_sim_mtx;
std::condition_variable begin_sim_cv;

/**
 * @brief (not my proudest function) formats decisecond duration into "%H:%M:%S.%DS" string.
 *        Sadly this functionality was not pre built into std::chrono :(
 * @param std::chrono::duration with period of decisecond
 * @return std::string
 */
std::string print_deci_seconds(std::chrono::duration<int , std::ratio<1,10>> &dur){
    int deci_seconds = dur.count();
    std::string time_str;
    time_str.reserve(15);
    if (deci_seconds >= 36000){ //time is over an hour
        int hours = std::floor(deci_seconds/36000);
        deci_seconds = deci_seconds%36000;
        if (hours>9){
            time_str += std::to_string(hours);
        }else{
            time_str += '0';
            time_str += std::to_string(hours);
        }
        
    }else{
        time_str += "00";
    }
    time_str += ':';
    if (deci_seconds >= 600){
        int min = std::floor(deci_seconds/600);
        deci_seconds = deci_seconds%600;
        if (min > 9){
            time_str += std::to_string(min);
        }else{
            time_str += '0';
            time_str += std::to_string(min);
        }
    }else{
        time_str += "00";
    }
    time_str += ':';
    
    std::stringstream stream;
    stream << std::fixed << std::setprecision(1) << deci_seconds/10.0;
    std::string sec = stream.str();

    if (deci_seconds/10.0 < 10){
        time_str += '0';
        time_str += sec;
    }else{
        time_str += sec;
    }
    return time_str;
}

/**
 * @brief sleeps for Train t loading time and displays nessesary info
 *        then pushes train t into priority queue.
 * 
 * @param Train t to be simulated
 */
void initialize_train(Train t){
    {   //wait to begin simulation until dispatcher is ready.
    std::unique_lock<std::mutex> begin_sim_ul(begin_sim_mtx); 
    begin_sim_cv.wait(begin_sim_ul);
    }

    std::this_thread::sleep_for (t.loading_time);
    
    cout_mutex.lock();
    std::cout << print_deci_seconds(t.loading_time) << " Train " << t.train_number-1<<" is ready to go ";
    if (t.direction == Direction::east){
        std::cout << "East" <<std::endl;
    }else{
        std::cout << "West" <<std::endl;
    }
    cout_mutex.unlock();
    
    if (t.direction == Direction::east){
        pq_mtx.lock();
        east_pq.push(t);
        pq_mtx.unlock();
    }else{
        pq_mtx.lock();
        west_pq.push(t);
        pq_mtx.unlock();    
    }
    pq_cond.notify_one();
}

/**
 * @brief Thread function to manage main tracks.
 *        Decides which train is to be sent based off
 *        assignement rules section 2.2. Then sleeps for
 *        chosen trains crossing_time.
 * 
 * @param total number of train that need to be dispatched as total_trains.
 */
void dispatcher(int total_trains){
    int trains_dispatched = 0;
    auto time = std::chrono::duration<int , std::ratio<1,10>>(0);
    Direction last_train_d = Direction::west;
    int same_d_count = 0;
    Train train_to_leave = Train(0,'e',0,0); //dummy temp train.

    //begin simulation when dispatcher is ready
    begin_sim_cv.notify_all();

    while (trains_dispatched != total_trains){
        
        { //small scope to auto destroy std::unique_lock.
        std::unique_lock<std::mutex> dispatch_ul(dispatch_mutex); 
        pq_cond.wait(dispatch_ul); //alerted after a train is pushed into a queue.
        }

        //sleep for 5 miliseconds to accomodate slight async amongst train threads.
        std::this_thread::sleep_for (std::chrono::milliseconds(5));
        
        while(!east_pq.empty() || !west_pq.empty()){
            
            pq_mtx.lock(); //critical section involving pq i/o's.           
            if (!east_pq.empty() && !west_pq.empty()){ //if both directions have trains waiting
                if (same_d_count == 4){ //check for starvation rule #4.
                    if (last_train_d == Direction::east){
                        //send a west train no mater what
                        train_to_leave = west_pq.top();
                        west_pq.pop();
                    }else{
                        //send a east train no matter what
                        train_to_leave = east_pq.top();
                        east_pq.pop();
                    }
                }else{ //no starvation rule.
                    if(east_pq.top().priority == west_pq.top().priority){
                        if (east_pq.top().direction != last_train_d){
                            //send east train
                            train_to_leave = east_pq.top();
                            east_pq.pop();
                        }else{
                            //send west train
                            train_to_leave = west_pq.top();
                            west_pq.pop();
                        }
                    }else{ //if priority are different send high priority train
                        if (east_pq.top().priority == Priority::high){
                            //send train east.top()
                            train_to_leave = east_pq.top();
                            east_pq.pop();
                        }else{
                            //send train west.top()
                            train_to_leave = west_pq.top();
                            west_pq.pop();
                        }
                    }
                }
            }else if(!east_pq.empty() && west_pq.empty()){
                //send east train
                train_to_leave = east_pq.top();
                east_pq.pop();
            }else{ //east_pq is empty send
                //send west train
                train_to_leave = west_pq.top();
                west_pq.pop();
            }
            pq_mtx.unlock(); //end of critical section

            if (train_to_leave.direction == last_train_d){
                same_d_count++;
            }else{ //if train chosen is different direction than last, update vars
                same_d_count = 1;   
                last_train_d = train_to_leave.direction;
            }

            if (train_to_leave.loading_time > time){
                time = train_to_leave.loading_time;
            }

            cout_mutex.lock();
            std::cout << print_deci_seconds(time) <<" Train " << train_to_leave.train_number-1<<" is ON main track going ";
            if (train_to_leave.direction == Direction::east){
                std::cout << "East" <<std::endl;
            }else{
                std::cout << "West" <<std::endl;
            }
            cout_mutex.unlock();

            std::this_thread::sleep_for (train_to_leave.crossing_time);
            time += train_to_leave.crossing_time;

            cout_mutex.lock();
            std::cout << print_deci_seconds(time) <<" Train " << train_to_leave.train_number-1<<" is OFF main track going ";
            if (train_to_leave.direction == Direction::east){
                std::cout << "East" <<std::endl;
            }else{
                std::cout << "West" <<std::endl;
            }
            cout_mutex.unlock();

            trains_dispatched++;
        }
    }
}

/**
 * @brief Reads filepath stream line by line calling Train object
 *        constructor then initializing it a train thread.
 * 
 * @param filepath to list of trains .txt file.
 * @param num_of_trains_out holds the number of trains in input file to be passed as reference.
 * @return std::vector<std::thread> so threads stay in scope to later be join()'ed.
 */
std::vector<std::thread> proccess_input_file(char* filepath, int &num_of_trains_out){
    std::ifstream input_file_object (filepath);
    num_of_trains_out = 0;
    char direction;
    int loading_time, crossing_time;
    std::vector<std::thread> train_threads;
    while (input_file_object >> direction >> loading_time >> crossing_time){
        num_of_trains_out++;
        Train temp_train(num_of_trains_out, direction, loading_time, crossing_time);
        train_threads.emplace_back(initialize_train, temp_train);
    }
    return train_threads;
}

int main(int argc, char *argv[]){
    if (argc != 2)  return 1;

    int total_trains;
    std::vector<std::thread> train_threads = proccess_input_file(argv[1], total_trains);
    std::thread dispatcher_thread(dispatcher, total_trains);

    //begin simulation

    for (auto &t: train_threads){
        t.join();
    }
    dispatcher_thread.join();
    return 0;
}