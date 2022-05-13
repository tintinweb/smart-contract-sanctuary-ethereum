contract Simple {
    string public name = 'No name';
    
    function setName(string newName) public {
        name = newName;
    }
}