/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.8.7;

contract Knjiznica {
    mapping(uint => Book) public Books;
	Book[] public BookArray;

    modifier isAvailable(uint id)
    {   
        require(Books[id].borrowed == false);
        _;
    }

    modifier isBorrowed(uint id)
    {   
        require(Books[id].borrowed == true);
        _;
    }

    modifier canExtend(uint id)
    {   
        require(Books[id].borrowed == true);
        require(Books[id].timesExtended < 3);
        _;
    }

    struct Book{
		string ISBN;
        string title;
        string author;
        bool borrowed;
		address user;
        uint returnDate;
        uint timesExtended;
    }

    function addNewBook(string memory ISBN, string memory title, string memory author) public {
        Book memory newBook;
		newBook.ISBN = ISBN;
        newBook.title = title;
        newBook.author = author;
        newBook.borrowed = false;
        newBook.returnDate = 0;
        newBook.user = address(0);
        newBook.timesExtended = 0;
		BookArray.push(newBook);
		uint id = BookArray.length;
        Books[id] = newBook;
    }

    constructor () 
    {
       Books[0] = Book("0-7475-3274-5", "Harry Potter and the philosopher's stone", "Rowling, J. K.", false, address(0), 0, 0);
	   BookArray.push(Books[0]);
       Books[1] = Book("0-261-10334-2", "The hobbit or There and back again", "Tolkien, J. R. R.", false, address(0), 0, 0);
	   BookArray.push(Books[1]);
       Books[2] = Book("0-7475-3849-2", "Harry Potter and the chamber of secrets", "Rowling, J. K.", false, address(0), 0, 0);
	   BookArray.push(Books[2]);
       // addNewBook()
    }

    function getBook(uint id) public view returns (string memory, string memory, string memory, bool, address, uint){
        Book memory s = Books[id];
        return (s.ISBN, s.title, s.author, s.borrowed, s.user, s.returnDate);
    }

    event eventBorrow(string ISBN, string title, string author, uint returnDate, address user);
	function borrowBook(uint id) public isAvailable(id) returns(uint result)
		{
			Book memory book = Books[id];
			book.borrowed = true;
			book.user = msg.sender;
			book.returnDate = block.timestamp + 1814400; 
            Books[id] = book;
            emit eventBorrow(book.ISBN, book.title, book.author, book.returnDate, book.user);
			return 0;
		}
		
		
    event eventReturn(bool successful, string ISBN, string title, string author);
    function returnBook(uint id) public isBorrowed(id) returns(uint result)
		{
            Book memory book = Books[id];
			if (book.user != msg.sender) {
				emit eventReturn(false, book.ISBN, book.title, book.author);
				return 1;
			}
			book = Books[id];
			book.borrowed = false;
			book.user = address(0);
			book.returnDate = 0;
			book.timesExtended = 0;
            Books[id] = book;
			emit eventReturn(true, book.ISBN, book.title, book.author);
			return 0;
		}

    function findBook(string memory search) public view returns(Book[] memory)
		{
            uint nBooks = 0;
            for (uint i=0; i<BookArray.length; i++) {
				if(keccak256(abi.encodePacked(BookArray[i].title)) == keccak256(abi.encodePacked(search)) || 
				   keccak256(abi.encodePacked(BookArray[i].ISBN)) == keccak256(abi.encodePacked(search)) ||
				   keccak256(abi.encodePacked(BookArray[i].author)) == keccak256(abi.encodePacked(search))) {
                    nBooks++;
				}
			}
            Book[] memory result = new Book[](nBooks);
            uint index = 0;
            for (uint i=0; i<BookArray.length; i++) {
				if(keccak256(abi.encodePacked(BookArray[i].title)) == keccak256(abi.encodePacked(search)) || 
				   keccak256(abi.encodePacked(BookArray[i].ISBN)) == keccak256(abi.encodePacked(search)) ||
				   keccak256(abi.encodePacked(BookArray[i].author)) == keccak256(abi.encodePacked(search))) {
					Book memory fBook = BookArray[i];
                    result[index] = fBook;
                    index++;
				}
			}
			return result;
		}
			
	event eventPodaljsanje(uint casVrnitve, uint steviloPodaljsanj);
    function podaljsanjeKnjige(uint id) public canExtend(id) returns(uint result)
		{
            Book memory book = Books[id];
			book.timesExtended += 1;
			book.returnDate = book.returnDate + 259200;
            Books[id] = book;
			emit eventPodaljsanje(book.returnDate, book.timesExtended);
			return 0;    
		}
}