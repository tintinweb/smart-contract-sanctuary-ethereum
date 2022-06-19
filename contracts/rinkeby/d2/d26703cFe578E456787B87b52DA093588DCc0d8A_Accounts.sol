// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Verify.sol";

contract Accounts is Verify{
    using Counters for Counters.Counter;
    Counters.Counter private accountId;

    event AccountCreated(AccountDetail,address _address);
    event AccountUpdated(AccountDetail,address _address);
    
    struct AccountDetail {
        string username;
        string displayName;
        string bio;
        string profilePic;
        bool isVerified;
    }

    mapping(uint => address) private idToAddress;
    mapping(address => uint) private addressToId;

    mapping(uint => AccountDetail) private accountDetails;

    address public owner;

    constructor(){
        owner = msg.sender;
    }

    function createAccount(string memory _username , string memory _displayName , string memory _bio , string memory _profilePic , bytes memory _signature , bytes32 _signedMessageHash) external {
        require(!isAccount(msg.sender) , "Account with your address already exists.");
        require(verify(owner,_signature,_signedMessageHash) == true , "Invalid Signature.");
      
        accountId.increment();
      
        idToAddress[accountId.current()] = msg.sender;
        addressToId[msg.sender] = accountId.current();
        accountDetails[addressToId[msg.sender]] = AccountDetail(_username , _displayName , _bio , _profilePic , false);

        emit AccountCreated(accountDetails[addressToId[msg.sender]],msg.sender);

    }

    function updateDetails(string memory _displayName , string memory _bio , string memory _profilePic) external {
        require(isAccount(msg.sender) , "Account with your address does not exists.");
       
        accountDetails[addressToId[msg.sender]].displayName = _displayName;
        accountDetails[addressToId[msg.sender]].bio = _bio;
        accountDetails[addressToId[msg.sender]].profilePic = _profilePic;

        emit AccountUpdated(accountDetails[addressToId[msg.sender]],msg.sender);

    }

    function changeAddress(address _newAddress) external {
        require(isAccount(msg.sender) , "Account with your address does not exists.");
        require(!isAccount(msg.sender) , "Account with your new address already exists.");

        uint _accountId = addressToId[msg.sender];

        addressToId[msg.sender] = 0;
        addressToId[_newAddress] = _accountId;
        idToAddress[_accountId] = _newAddress;

        emit AccountUpdated(accountDetails[_accountId],_newAddress);

    }

    function changeAccountStatus(uint256 _accountId , bool status) external {
        require(msg.sender == owner , "This is an only owner function.");
        accountDetails[_accountId].isVerified = status;

        emit AccountUpdated(accountDetails[_accountId],msg.sender);

    }

    function getAccountDetails(uint256 _accountId) public view returns (AccountDetail memory){
        require(_accountId > 0 && _accountId <= accountId.current() , "Account does not exists.");
        return accountDetails[_accountId];
    }

    function getAccountDetails(address _accountAddress) public view returns (AccountDetail memory){
        require(isAccount(msg.sender) , "Account does not exists.");
        return accountDetails[addressToId[_accountAddress]];
    }

    function isAccount(address _address) public view returns (bool){
        if(addressToId[_address] == 0){
            return false;
        }else{
            return true;
        }
    }

    function totalAccounts() external view returns (uint256) {
        return accountId.current();
    }

    function transferOwnership(address newOwner) public virtual {
        require(owner == msg.sender , "Only owner can transfer the ownership.");
        require(newOwner != address(0) , "New owner is the zero address.");
        owner = newOwner;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Verify{

    function verify (address _signer, bytes memory _signature, bytes32 _signedMessageHash) public pure returns (bool){
        return recoverSigner(_signedMessageHash, _signature) == _signer;
    }

    function recoverSigner (bytes32 _signedMessageHash, bytes memory _signature) internal pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
        require(_signature.length == 65, "Invalid signature length"); 
    
        assembly {
            r:= mload(add(_signature, 32))
            s:= mload(add(_signature, 64))
            v:=byte(0, mload(add(_signature, 96)))
        }
    
        return ecrecover(_signedMessageHash, v, r, s);
    }

}