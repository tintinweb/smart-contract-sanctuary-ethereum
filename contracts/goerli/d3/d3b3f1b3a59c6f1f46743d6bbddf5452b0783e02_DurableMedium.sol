/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

pragma solidity ^0.6.0;

contract DurableMedium {
    // Definicja struktury do przechowywania informacji o dokumencie
    struct DocumentInfo {
        uint256 id;
        string documentName;
        bytes32 documentHash;
        bytes32[] authorizedEmails;
        uint256 timestamp;
        string description;
    }

    // Mapy, które będą przechowywać informacje o dokumentach
    mapping(bytes32 => DocumentInfo) private documentsFromHash;
    mapping(uint256 => DocumentInfo) private documentsFromId;
    uint private documentCount;
    address public owner;


    // Konstruktor kontraktu
    constructor(address _owner) public {
        require(_owner != address(0), "Adres wlasciciela nie moze byc zainicjowany z wartoscia null");
        owner = _owner;
    }

    // Metoda, która będzie dodawać dokumenty do mapy
    function addDocument(
        string memory _documentName,
        bytes32 _documentHash,
        bytes32[] memory _authorizedEmails,
        uint256 _timestamp,
        string memory _description
    ) public {
        // Sprawdzenie adresu, z którego dodawany jest dokument
        require(msg.sender == owner, "Tylko wlasciciel moze dodac nowy dokument");
        // Sprawdzenie, czy dokument o podanym hashu już istnieje
        require(
            documentsFromHash[_documentHash].authorizedEmails.length == 0,
            "Dokument o podanym hashu juz istnieje"
        );
        require(
            bytes(_description).length <= 150,
            "Opis dokumentu jest zbyt dlugi - przekracza 150 znakow"
        );
        // Dodaj dokument do trwałego nośnika
        DocumentInfo memory documentToAdd = DocumentInfo(
            documentCount,
            _documentName,
            _documentHash,
            _authorizedEmails,
            _timestamp,
            _description
        );
        documentsFromHash[_documentHash] = documentToAdd;
        documentsFromId[documentCount] = documentToAdd;
        documentCount++;
    }

    // Metoda, która zwraca informacje o dokumencie na podstawie jego hasha
    function getDocumentInfo(bytes32 _documentHash)
        public
        view
        returns (
            uint256,
            string memory,
            bytes32,
            bytes32[] memory,
            uint256,
            string memory
        )
    {
        DocumentInfo memory documentInfo = documentsFromHash[_documentHash];
        return (
            documentInfo.id,
            documentInfo.documentName,
            documentInfo.documentHash,
            documentInfo.authorizedEmails,
            documentInfo.timestamp,
            documentInfo.description
        );
    }

    // Metoda, która zwraca id dokumentu na podstawie jego hasha
    function getDocumentId(bytes32 _documentHash)
        public
        view
        returns (
            uint256
        )
    {
        DocumentInfo memory documentInfo = documentsFromHash[_documentHash];
        return (
            documentInfo.id
        );
    }

    // Metoda, która zwraca id dokumentu na podstawie jego hasha
    function getDocumentHash(uint256 _documentId)
        public
        view
        returns (
            bytes32
        )
    {
        DocumentInfo memory documentInfo = documentsFromId[_documentId];
        return (
            documentInfo.documentHash
        );
    }

    function ifArrayContains(bytes32[] memory _array, bytes32 _value)
        private
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _value) {
                return true;
            }
        }
        return false;
    }

    // Metoda, która sprawdza czy podany mail ma dostęp do określonego dokumentu
    function checkMailAccess(bytes32 _documentHash, bytes32 _mailHash)
        public
        view
        returns (bool)
    {
        DocumentInfo memory documentInfo = documentsFromHash[_documentHash];
        return ifArrayContains(documentInfo.authorizedEmails, _mailHash);
    }

    // Metoda zwracająca aktualną liczbę dokumentów w trwałym nośniku
    function numberOfDocuments() public view returns (uint){
        return documentCount;
    }
}