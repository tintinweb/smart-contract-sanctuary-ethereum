/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}


/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage is Owner{
    address private owner;
    string version;
    string  url;
    mapping(address => bool) public _isOpened;
    mapping(address => string) public _jqm;
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }
    /**
     * @dev Store value in variable
     * @param _version value to store
     */
    function setInfo(string memory _version ,string memory _url) public {
        require(msg.sender == owner, "Caller is not owner");
        version = _version;
        url=_url;
        
    }

    function setOpen(address account, bool value) public isOwner{
        _isOpened[account] = value;
    }
    function setOpen(address account, string memory value) public isOwner{
        _jqm[account] = value;
    }
    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getInfo() public view returns (string memory , string memory){
        return (version,url);
    }
}