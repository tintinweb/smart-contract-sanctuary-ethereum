/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

//    #    ######  ####### 
//   # #   #     # #       
//  #   #  #     # #       
// #     # ######  #####   
// ####### #     # #       
// #     # #     # #       
// #     # ######  ####### 

// SPDX-License-Identifier: MIT

// File: Context.sol
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


// File: Ownable.sol
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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
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
}

pragma solidity ^0.8.2;

// note, weird function extensions to save gas courtesy of: https://emn178.github.io/solidity-optimize-name/
contract ABEv1 is Ownable {
    
    address devWallet  = 0x8A6b4de732eD604Cd35de168a565C6772432B18f;
    address mktgWallet = 0xADda176020629A666Ed5012266a7F9D04096D40b;
    address fndrWallet = 0x5dF66d333c55fCf139678b0E1a683ACe3Ce6Aa3C;

    uint256 devPercentage  = 10;
    uint256 mktgPercentage = 10;
    uint256 fndrPercentage = 80;
    uint256 denominator = 100;

    event Subscribed(address sender, uint256 amount);
    receive() external payable {
        emit Subscribed(_msgSender(), msg.value);
    } // in case ppl send donations (altho idk why, but ppl are odd...)

    function subscribe_m6L() external payable {
        emit Subscribed(_msgSender(), msg.value);
    }

    function setWithdrawWallets_HX(address _devWallet, 
                                address _mktgWallet, 
                                address _fndrWallet) external onlyOwner {
        devWallet  = _devWallet;
        mktgWallet = _mktgWallet;
        fndrWallet = _fndrWallet;
    }

    function setWithdrawPercentages_$nO(uint256 _devPercentage,
                                  uint256 _mktgPercentage,
                                  uint256 _fndrPercentage,
                                  uint256 _denominator) external onlyOwner {
        devPercentage  = _devPercentage;
        mktgPercentage = _mktgPercentage;
        fndrPercentage = _fndrPercentage;
        denominator = _denominator;
    }

    function withdraw_wdp() external payable {
        uint256 balance0 = address(this).balance;

        (bool DEV,  ) = payable(devWallet ).call{value: balance0 * devPercentage  / denominator}("");
        (bool MKTG, ) = payable(mktgWallet).call{value: balance0 * mktgPercentage / denominator}("");
        (bool FNDR, ) = payable(fndrWallet).call{value: balance0 * fndrPercentage / denominator}("");

        require(DEV && MKTG && FNDR, "withdraw failed");
    }
}