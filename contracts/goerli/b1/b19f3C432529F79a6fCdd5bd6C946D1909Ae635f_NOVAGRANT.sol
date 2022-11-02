/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is 0x address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Functional {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    bool private _reentryKey = false;
    modifier reentryLock {
        require(!_reentryKey, "attempt reenter locked function");
        _reentryKey = true;
        _;
        _reentryKey = false;
    }
}

contract ERC20 {
    function totalSupply() external view returns (uint256){}
    function balanceOf(address account) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function allowance(address owner, address spender) external view returns (uint256){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
    
    //proxy access functions:
    function sellNova(uint256 coins) public{}
    function buyNova() payable public{}
    function novaPerEth() public view returns (uint256){}
}

contract NOVAGRANT is Ownable, Functional {
    ERC20 NOVACOIN;  // $NOVA

    struct Grant{
        address fundingWallet;
        uint256 fundingRequired;
        uint256 totalPledged;
        bool reqMet;
        bool NGMI;
    }

    mapping(uint256 => Grant) grants;
    //Grant [] public grants; //keep track of all grants by index (serial number)

    mapping(address => mapping(uint256 => uint256)) userPledged;



    function sendPledge( uint256 amount, uint256 projectSN ) external reentryLock {
        require(NOVACOIN.allowance(_msgSender(), address(this)) >= amount, "Txn requires approval");
        require(NOVACOIN.balanceOf(_msgSender()) >= amount, "Not enough $NOVA");
        require(grants[projectSN].NGMI == false, "Project is closed");

        NOVACOIN.transferFrom(_msgSender(), address(this), amount);
        
        //do some other stuff to log the txn
        userPledged[_msgSender()][projectSN] += amount;
        grants[projectSN].totalPledged += amount;
        if (grants[projectSN].totalPledged >= grants[projectSN].fundingRequired) { grants[projectSN].reqMet = true; }
    }

    function claimPledge( uint256 projectSN ) external reentryLock {
        require(grants[projectSN].NGMI == true, "Project is still active");

        uint256 amount = userPledged[_msgSender()][projectSN];
        NOVACOIN.transfer(_msgSender(), amount);
        grants[projectSN].totalPledged -= amount;
        userPledged[_msgSender()][projectSN] = 0;
    }

    function createGrant( uint256 projectSN, uint256 reqFunding, address wallet) external onlyOwner {
        grants[projectSN].fundingRequired = reqFunding;
        grants[projectSN].fundingWallet = wallet;
    }

    function payoutGrant( uint256 projectSN ) external onlyOwner {
        // Swap tokens back for eth and payout to the collection wallet for this project
        // Requires this contract to be proxied on the token contract
        uint256 Ncoins = grants[projectSN].totalPledged;
        uint256 exchangeRate = NOVACOIN.novaPerEth();
        uint256 ethCoins = Ncoins / exchangeRate;

        NOVACOIN.sellNova(Ncoins); //should burn the tokens and send eth back to this contract

        (bool success, ) = grants[projectSN].fundingWallet.call{value: ethCoins}("");
        require(success, "Transaction Unsuccessful");
    }

    function removeGrant( uint256 projectSN ) external onlyOwner {
        grants[projectSN].NGMI = true;
    }

    function changeWallet( uint256 projectSN, address newWallet ) external onlyOwner {
        grants[projectSN].fundingWallet = newWallet;
    }
    
    function viewWallet( uint projectSN ) public view returns (address) {
    	return grants[projectSN].fundingWallet;
    }

    function checkFunding (uint256 projectSN) public view returns (uint256) {
        return grants[projectSN].totalPledged;
    }

    function fundingNeeded (uint256 projectSN) public view returns (uint256) {
        return grants[projectSN].fundingRequired;
    }

    function grantSuccess (uint256 projectSN) public view returns (bool) {
        return grants[projectSN].reqMet;
    }

    function setNovaCoinAddress( address newaddress ) external onlyOwner {
        NOVACOIN = ERC20(newaddress);
    }
}