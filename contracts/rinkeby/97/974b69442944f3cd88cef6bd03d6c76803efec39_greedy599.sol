/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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


contract greedy599 is Ownable{

    event Start(address indexed payee);
    event Invest(address indexed payee, uint256 key_price, uint256 last);
    event Distribute(address indexed payee, uint256 investorTokens);
    event Breaking(address indexed payee, uint256 investorTokens);

    mapping(address=>bool) record;
    mapping(address=>uint) public investorTokens;
    address payable[] public investors; // array of investors
    address payable public leader;
    uint public key_price = 1000000000000000 wei;
    uint public last;
    // uint public balance;
    bool public break_sign = true;

    function start() public payable onlyOwner{
        require(msg.value == key_price && break_sign);
        investors.push(payable(msg.sender));
        record[msg.sender] = true;
        break_sign = false;
        investorTokens[msg.sender] += key_price / 100;
        key_price += 1000000000000000 wei;
        leader = payable(msg.sender);
        last = block.timestamp;
        emit Start(msg.sender);
    }

    function invest() public payable {
        require(msg.value == key_price && !break_sign);
        if (!record[msg.sender]){
            investors.push(payable(msg.sender));
            record[msg.sender] = true;
        }
        investorTokens[msg.sender] += key_price / 100;
        
        leader = payable(msg.sender);
        last = block.timestamp;
        emit Invest(msg.sender, key_price, last);
        key_price += 1000000000000000 wei;
    }

    function distribute() public onlyOwner {
        require(!break_sign);
        for(uint i = 0; i < investors.length; i++) { 
            investors[i].transfer(investorTokens[investors[i]]);
            emit Distribute(investors[i], investorTokens[investors[i]]);
        }
    }

    function breaking() public onlyOwner{
        require(!break_sign);
        break_sign = true;
        emit Breaking(leader, address(this).balance / 2);
        leader.transfer(address(this).balance / 2);
        // balance /= 2;
        uint tmp = address(this).balance / investors.length;
        for(uint i = 0; i < investors.length; i++) { 
            investors[i].transfer(tmp);
            emit Breaking(investors[i], tmp);
            investorTokens[investors[i]] = 0;
            record[investors[i]] = false;
        }
        delete investors;
        key_price = 1000000000000000 wei;
        leader = payable(address(0));
    }
}