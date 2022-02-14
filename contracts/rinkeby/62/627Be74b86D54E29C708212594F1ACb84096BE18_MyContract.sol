/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Copy_20220213.sol



pragma solidity >0.5;


contract MyContract is Ownable {

    mapping (address => bool) public allowedEntryList;

    function addToList(address _allowedEntry) public onlyOwner {    
        allowedEntryList[_allowedEntry]=true;
    }

    function showAllowedList(address _addrToCheck) public returns (bool) {
      return allowedEntryList[_addrToCheck];
    }

    modifier onlyAllowed() {
        require(allowedEntryList[_msgSender()] == true, "onlyAllowed: the caller is not granted access");
        _;
    }

    //struct entspricht 'Tabellenspalten' - hier wird die Struktur der Tabelle definiert
    struct DataType {
        //automatisch angelegt - folgende Variablen werden automatisch bei jeder Ausführung des Contracts ausgefüllt
        address senderId;
        address[] authorisedIds;
        //durch Versender angelegt - der Versender, der eine neue Lieferung anlegt, kann folgende Variablen beschreiben
        uint256 batchNumber;
        uint256[] prevOrderIds;
        uint256 shipmentDate;
        string workPerformed;
        string article;
        address receiverId;
        //durch Empfänger angelegt - der vom Versender eingetragene Empfänger hat die Möglichkeit, folgende Variablen zu verändern
        string deliveryConfirmation;
    }
    
    //Liste der Tabellenspalten: Zeilen
    mapping (uint256 => DataType) table;

  //hier wird ein neuer Datensatz angelegt. Der Versender vergibt verpflichtend eine Sendungsnummer (orderId) und kann anschließend weitere Felder beschreiben
    function addRow(uint256 _orderId, 
                    uint256 _batchNumber, 
                    uint256 _prevOrderId, 
                    uint256 _shipmentDate, 
                    string memory _workPerformed, 
                    string memory _article,
                    address _receiverId) public onlyAllowed {
        //Abfrage nach gültiger orderId
        require(_orderId > 0);
        //Abfrage nach neuem Datensatz (da senderId immer automatisch angelegt wird, kann dieses Datum stellvertretend abgefragt werden)
        address _senderId = table[_orderId].senderId;
        require(_senderId == address(0));
        //senderId wird automatisch zugewiesen
        _senderId = msg.sender;
        //folgende Variablen werden vom Empfänger beschrieben und daher hier zunächst auf '0' bzw. 'False' gesetzt
        string memory _deliveryConfirmation = "False";
        //Zugangsberechtigungen anlegen: Sender und Empfänger werden berechtigt, sowie alle Berechtigten der vorherigen Lieferungen (prevOrderId)
        //address[] memory _authorisedIds = [_senderId, _receiverId];
        address[] memory _authorisedIds;
        //uint256[] memory _prevOrderIds = [_prevOrderId];
        uint256[] memory _prevOrderIds;
        if (_prevOrderId != 0 ) {
            _prevOrderIds = table[_prevOrderId].prevOrderIds;
            _authorisedIds = table[_prevOrderId].authorisedIds;
        }
        /* _prevOrderIds.push(_prevOrderId);
        _authorisedIds.push(_senderId);
        _authorisedIds.push(_receiverId); */

        table[_orderId] = DataType(_senderId,
                                    _authorisedIds,
                                    _batchNumber, 
                                    _prevOrderIds, 
                                    _shipmentDate, 
                                    _workPerformed, 
                                    _article,
                                    _receiverId,
                                    _deliveryConfirmation);
        table[_orderId].prevOrderIds.push(_prevOrderId);
        table[_orderId].authorisedIds.push(_senderId);
        table[_orderId].authorisedIds.push(_receiverId);
                                    
    }

    //die folgende Funktion dient zur Abfrage von Datensätzen. Im aktuellen Schritt kann dafür lediglich nach der Bestellnummer gesucht werden
    function getRow(uint256 _orderId) public view returns (address _senderId,
                                                            address[] memory _authorisedIds,
                                                            uint256 _batchNumber, 
                                                            uint256[] memory _prevOrderIds,
                                                            uint256 _shipmentDate, 
                                                            string memory _workPerformed, 
                                                            string memory _article,
                                                            address _receiverId,
                                                            string memory _deliveryConfirmation){
        _senderId = table[_orderId].senderId;
        _authorisedIds = table[_orderId].authorisedIds;
        _batchNumber = table[_orderId].batchNumber;
        _prevOrderIds = table[_orderId].prevOrderIds;
        _shipmentDate = table[_orderId].shipmentDate;
        _workPerformed = table[_orderId].workPerformed;
        _article = table[_orderId].article;
        _receiverId = table[_orderId].receiverId;
        _deliveryConfirmation = table[_orderId].deliveryConfirmation;
        
    }

    //Der vom Versender eingetragene Empfänger hat mit der folgenden Funktion die Möglichkeit, den Empfang der Lieferung zu bestätigen
    function changeRow(uint256 _orderId,
                        string memory _deliveryConfirmation) public {
        //orderId muss vorhanden sein
        require(_orderId > 0, "keine gueltige orderId");
        //nur der Empfänger darf diese Funktion ausführen
        address _receiverId = table[_orderId].receiverId;
        require(msg.sender == _receiverId);
        
        address _senderId = table[_orderId].senderId;
        address[] memory _authorisedIds = table[_orderId].authorisedIds;
        uint256 _batchNumber = table[_orderId].batchNumber;
        uint256[] memory _prevOrderIds = table[_orderId].prevOrderIds;
        uint256 _shipmentDate = table[_orderId].shipmentDate;
        string memory _workPerformed = table[_orderId].workPerformed;
        string memory _article = table[_orderId].article;
        table[_orderId] = DataType(_senderId,
                                    _authorisedIds,
                                    _batchNumber, 
                                    _prevOrderIds, 
                                    _shipmentDate, 
                                    _workPerformed, 
                                    _article,
                                    _receiverId,
                                    _deliveryConfirmation);

    }
    
}