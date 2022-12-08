/**
 *Submitted for verification at Etherscan.io on 2022-12-08
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
    function proxyMint(address reciever, uint256 amount) external {}
    function proxyTransfer(address from, address to, uint256 amount) external {}
    function balanceOf(address account) public view returns (uint256) {}

    function getUserStakedContracts( address staker ) external view returns (address[] memory){}
    function getUserStakedTokenIndex( address staker ) external view returns (uint256[] memory){}
    function getUserStakedTokenIds( address staker ) external view returns (uint256[] memory){}
    function getUserStakedTimestamps( address staker ) external view returns (uint256[] memory){}
}

contract XARAREWARDS is Ownable, Functional {
    //settings for bonus 1000XARA
    mapping (uint256 => mapping(uint256 => bool)) bonusClaimed; // bonusClaimed[tokenId][bonusRound]
    uint256 private _coinBonusPerToken;
    uint256 private _bonusModFactor;
    uint256 private _bonusRound;

    string private _name;
    
    ERC20 XARA; //define the coin contract
    address XAR; // address of the xarians erc721 smart contract

    constructor() {
        _name = "XARA REWARDS";

        _bonusModFactor = 20;
        XAR = 0xe207578AB49f553534c025ee348Ac33e81cc6018;
        XARA = ERC20(0xeF4de0E2668BcF6367192E353996E69667AF1495);
    }

    ///////////////////// Reward and Bonus Functions /////////////////////
    function claimBonus() public reentryLock {
        uint256 claimAmount = 0;

        address [] memory sContracts = XARA.getUserStakedContracts( _msgSender());
        uint256 [] memory sTokenIds = XARA.getUserStakedTokenIds( _msgSender());

    	for (uint256 i=0; i < sContracts.length; i++){
            if (sContracts[i] == XAR){
                if ((sTokenIds[i] % 5) == _bonusModFactor){
                    if (bonusClaimed[sTokenIds[i]][_bonusRound] == false){
                        bonusClaimed[sTokenIds[i]][_bonusRound] = true;
                        claimAmount += _coinBonusPerToken;
                    }
                }
            }
    	}

    	//mint bonus
    	XARA.proxyMint(_msgSender(), claimAmount);
    }
    
    function checkBonus(address holder) public view returns (uint256){
        uint256 claimAmount = 0;

        address [] memory sContracts = XARA.getUserStakedContracts( holder );
        uint256 [] memory sTokenIds = XARA.getUserStakedTokenIds( holder );

    	for (uint256 i=0; i < sContracts.length; i++){
            if (sContracts[i] == XAR){
                if ((sTokenIds[i] % 5) == _bonusModFactor){
                    if (bonusClaimed[sTokenIds[i]][_bonusRound] == false){
                        claimAmount += _coinBonusPerToken;
                    }
                }
            }
    	}

        return claimAmount;
    }

    function setBonus(uint256 modFactor, uint256 newBonusWholeCoins) public onlyOwner{
        _bonusModFactor = modFactor;
        _coinBonusPerToken = newBonusWholeCoins * (10 ** 18);
        _bonusRound++;
    }

    function setCoinContract(address coinSmartContract) public onlyOwner{
        XARA = ERC20(coinSmartContract);
    }

    function setXariansContract(address ERC721SmartContract) public onlyOwner{
        XAR = ERC721SmartContract;
    }

}