function scrollToSection(sectionId) {
    var section = document.getElementById(sectionId);
    section.scrollIntoView(true);
    window.scroll(0, window.scrollY - 70)
}