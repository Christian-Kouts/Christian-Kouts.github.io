#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h> 

#define MAX_LINES 100
#define MAX_LINE_LEN 80
#define MAX_STRING_LEN 20
#define MAX_UNIQUE_WORDS 500

typedef struct unique_word {
    char word[MAX_STRING_LEN];      //
    int line_num;                   //line num where word occured in input file
}unique_word;

//compare funnction used for qsort().
int compare_unique_words(const void *p1, const void* p2){   
    unique_word *a = (unique_word *)p1;
    unique_word *b = (unique_word *)p2;
    
    // if (strcmp((unique_word*)a->word,(unique_word*)b->word)==0){
    //     return ((unique_word*)a->line_num - (unique_word*)b->line_num);
    // }else{
    //     return (strcmp((unique_word*)a->word,(unique_word*)b->word));
    // }
    return (strcmp(a->word,b->word));

}

int main(int argc, char* argv[]){
    bool exclude_words_state;
    FILE *filter;
    FILE *input;
    char flag[] = "-e";
    bool in_filter_state;
    char input_file[MAX_LINES][MAX_LINE_LEN];
    char words_excluded[MAX_LINES][MAX_STRING_LEN];
    int excluded_len;
    char word [MAX_STRING_LEN];
    char line [MAX_LINE_LEN];
    unique_word unique_words[MAX_UNIQUE_WORDS];
    int unique_words_len = 0;
    int longest_unique_word_len = 0;
    
    //printf("Starting main\n");
    //printf("Processing inputs...\n");

    if (argc <= 1 || argc == 3 || argc >= 5){      
        //fprinf(stderr, "Incorrect input format\n");
        exit(1);
    }

    if (argc <= 2){
        input = fopen(argv[1],"r");
        exclude_words_state = false;
        if (input == NULL){
            //fprintf(stderr, "unable to open %s\n", argv[1]);
            return 1;
        }
    }else{
        if (strcmp(argv[1],flag) == 0){
            filter = fopen(argv[2],"r");
            input = fopen(argv[3],"r");
            exclude_words_state = true;
            if (input == NULL || filter == NULL){
                //fprintf(stderr, "unable to open %s or %s\n", argv[2], argv[3]);
                return 1;
            }
        }
        if (strcmp(argv[2],flag) == 0){
            filter = fopen(argv[3],"r");
            input = fopen(argv[1],"r");
            exclude_words_state = true;
            if (input == NULL || filter == NULL){
                //fprintf(stderr, "unable to open %s or %s\n", argv[1], argv[3]);
                return 1;
            }
        }
    }
    //printf("Inputs processed...\n");

    //printf("Creating excluding list if nessesary...\n");
    if (exclude_words_state){
        excluded_len = 0;
        while (fgets(word, MAX_STRING_LEN,filter) != NULL){
            word[strcspn(word, "\n")] = 0;
            strncpy(words_excluded[excluded_len], word, MAX_STRING_LEN);
            excluded_len++;
            //printf("%s\n", word);
        }
    }
    //printf("Excluded words arrayed...\n");
    

    //printf("Creating input file array...\n");
    int lines_in_file = 0;
    while (fgets(line, MAX_LINE_LEN,input) != NULL){
        line[strcspn(line, "\n")] = 0;
        strncpy(input_file[lines_in_file], line , MAX_LINE_LEN);
        lines_in_file++;
    }
    
    //printf("creating input file copy");
    char input_file_copy[MAX_LINES][MAX_LINE_LEN];
    for (int i = 0; i < lines_in_file; i++){
        strncpy(input_file_copy[i],input_file[i], MAX_LINE_LEN);
    }

    //printf("Creating unique words list...\n");
    for (int i = 0; i<lines_in_file; i++){
        const char s[2] = " ";
        char *token;
        token = strtok(input_file[i], s);
        while (token != NULL){
            in_filter_state = false;
            for (int i = 0; i < excluded_len; i++){ //-1
                //printf(" %s, %s\n", token, words_excluded[i]);
                
                if (strcmp(words_excluded[i],token)==0){
                    in_filter_state = true;
                    break;
                }
            }
            if (!in_filter_state){
                strncpy(unique_words[unique_words_len].word, token, MAX_STRING_LEN);
                unique_words[unique_words_len].line_num = i;
                if (strlen(token)>=longest_unique_word_len){
                    longest_unique_word_len = strlen(token);
                }
                //printf("%s %d\n",unique_words[unique_words_len].word,unique_words[unique_words_len].line_num);
                unique_words_len++;   
            }
            token = strtok(NULL, s);
        }
    }
    //printf("Unique words arrayed...\n");
    

    //atempting to use q sort to sort list of unique word into alphabetical order.
    qsort(unique_words, unique_words_len, sizeof(unique_word), compare_unique_words);

    for (int i = 0; i < unique_words_len; i++){
        if (i > 0){
            if (strcmp(unique_words[i].word, unique_words[i-1].word) == 0 && unique_words[i].line_num == unique_words[i-1].line_num){
                continue;
            }
        }
        
        for (int j = 0; j < strlen(unique_words[i].word); j++){
        printf("%c", toupper(unique_words[i].word[j]));

        }
        for (int u = 0; u <longest_unique_word_len+2-strlen(unique_words[i].word); u++){
            printf(" ");
        }
        printf("%s (%d",input_file_copy[unique_words[i].line_num], unique_words[i].line_num+1);
        if (i < unique_words_len-1){
            if (strcmp(unique_words[i].word, unique_words[i+1].word) == 0 && unique_words[i].line_num == unique_words[i+1].line_num){
                printf("*");
            }
        }
        printf(")\n");
    }


    return 0;
}