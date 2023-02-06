// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IFundraiser.sol";
import "./IToken.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


enum FundraiseState {
    Opened,
    Closed
}

contract Fundraiser is Ownable, IFundraiser{

    struct Fundraise {

        uint48  id;
        address creator;
        address beneficiary;
        
        FundraiseState state;

        address[] assetAddresses;
        mapping(address => uint) balances;
    }

    Fundraise[] fundraises;
    
    function totalUniqueAssets(uint48 id) private view returns(uint) {
        return fundraises[id].assetAddresses.length;
    }

    function getAssetAddress(uint48 id, uint48 _i) private view returns(address){
        return fundraises[id].assetAddresses[_i];
    }

    function getAssetBalance(uint48 id, address asset) private view returns(uint){
        return fundraises[id].balances[asset];
    }
    function isAssetInFundraise(uint48 id, address asset) private view returns(bool){

        for(uint48 i = 0; i < fundraises[id].assetAddresses.length; i++)
            if(fundraises[id].assetAddresses[i] == asset)
                return true;
        return false;
    }

    function addNewAsset(uint48 id, address asset) private {
        if(!isAssetInFundraise(id, asset))
            fundraises[id].assetAddresses.push(asset);
    }
    

    // Info functions:

    function getFundraisingCreator(uint48 _id) external view returns(address) {
        return fundraises[_id].creator;
    }

    function getFundraisingAssets(uint48 _id) external view returns(address[] memory assets, uint[] memory amounts){
        uint len = totalUniqueAssets(_id);
        
        assets = new address[](len);
        amounts = new uint[](len);

        for(uint48 i = 0; i < len; i++){
            assets[i] = fundraises[_id].assetAddresses[i];
            amounts[i] = fundraises[_id].balances[assets[i]];
        }
        
    }


    function addFundraising(address _beneficiary) public override returns(uint48 id){
        
        id = uint48(fundraises.length);
        
        // Workaround to push a struct that has a nested mapping
        Fundraise storage fr = fundraises.push();
        fr.id = id;
        fr.creator = msg.sender;
        fr.beneficiary = _beneficiary;
        fr.state = FundraiseState.Opened;

        emit FundraiseCreated(id);
    }

    function liquidateFundraising(uint48 _id) public override onlyCreator(_id) onlyOpened(_id) {
        
        uint length = totalUniqueAssets(_id);

        for(uint48 i = 0; i < length; i++){

            address payable tokenAddr = payable(getAssetAddress(_id, i));
            if(tokenAddr != payable(address(this)))
                // Not a native token
                require(IERC20(tokenAddr).transfer(fundraises[_id].beneficiary, getAssetBalance(_id, tokenAddr)));
            else
                // Native token
                payable(fundraises[_id].beneficiary).transfer(getAssetBalance(_id, address(this)));

        }
        fundraises[_id].state = FundraiseState.Closed;
        emit FundraiseLiquidated(_id, fundraises[_id].beneficiary);
    }

    function fund(uint48 _id) payable public override {
        require(msg.value > 0, "Funding value must be greater than zero");

        fundraises[_id].balances[address(this)] += msg.value;
        addNewAsset(_id, address(this));
        emit FundraiseFunded(_id, msg.sender, address(this), msg.value);
    }

    function fundToken(uint48 _id, address _asset, uint amount) public override{
        require(IERC20(_asset).transferFrom(msg.sender, address(this), amount));
        fundraises[_id].balances[_asset] += amount;
        addNewAsset(_id, _asset);
        emit FundraiseFunded(_id, msg.sender, _asset, amount);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "There are no funds to withdraw");

        payable(msg.sender).transfer(balance);
    }

    receive() external payable {
    }

    modifier onlyCreator (uint48 _id) {
        require(fundraises[_id].creator == msg.sender, "Fundraise can only be liquidated by its creator");
        _;
    }

    modifier onlyOpened (uint48 _id) {
        require(fundraises[_id].state == FundraiseState.Opened, "Fundraise already liquidated");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @title IFundraiser
/// @dev Comprises the behavior of a Fundraiser that is able to create and liquidate fundraisings
interface IFundraiser {
    
    function addFundraising(address _beneficiary) external returns(uint48);
    function liquidateFundraising(uint48 _id) external;
    function fund(uint48 _id) payable external;
    function fundToken(uint48 _id, address _asset, uint amount) external;
    
    event FundraiseCreated(uint48);
    event FundraiseLiquidated(uint48, address);
    event FundraiseFunded(uint48, address funder, address token, uint amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IToken {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}