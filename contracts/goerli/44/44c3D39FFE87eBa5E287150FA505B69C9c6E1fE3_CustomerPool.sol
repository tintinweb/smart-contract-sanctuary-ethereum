// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library DataTypes {

    struct PurchaseProduct {
        address customerAddress;
        uint256 amount;
        uint256 releaseHeight;
        address tokenAddress;
        uint256 customerReward;
        uint256 cryptoQuantity;
    }

    struct CustomerByCrypto {
        address customerAddress;
        address cryptoAddress;
        uint256 amount;
    }

    struct ExchangeTotal {
        address tokenIn;
        address tokenOut;
        uint256 tokenInAmount;
        uint256 tokenOutAmount;
    }

    struct ProductInfo {
        uint256 productId; 
        uint256 conditionAmount;
        uint256 customerQuantity;
        uint256 cryptoQuantity;
        address cryptoType;
        ProgressStatus resultByCondition;
        address cryptoExchangeAddress;
        uint256 releaseHeight;
        ProductType productType;
        uint256 totalCustomerReward;
        bool isSatisfied;
        uint256 totalAvailableVolume;
    }
    
    enum ProductType {
        BUY_LOW,
        SELL_HIGH
    }

    enum ProgressStatus {
        UNDELIVERED,
        REACHED,
        UNREACHED
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "../library/common/DataTypes.sol";
import "../library/open-zeppelin/Ownable.sol";

contract CustomerPool is Ownable {
    address public proxy;

    mapping(uint256 => DataTypes.PurchaseProduct[]) productPurchasePool;

    /**
     * @param _proxy 代理合约地址
     */
    constructor(address _proxy) {
        proxy = _proxy;
    }

    /**
     * notice 更新代理合约地址
     * @param _proxy 代理合约地址
     */
    function updateProxy(address _proxy) public onlyOwner {
        proxy = _proxy;
    }

    modifier onlyProxy() {
        require(proxy == msg.sender, "Ownable: caller is not the proxy");
        _;
    }

    /**
     * Returns DataTypes.PurchaseProduct
     * notice 获取指定产品的价格
     * @param _pid 产品地址.
     * @param _customerAddress 用户钱包地址
     * @param _releaseHeight 区块高度
     */
    function getSpecifiedProduct(
        uint256 _pid,
        address _customerAddress,
        uint256 _releaseHeight
    ) public view returns (DataTypes.PurchaseProduct memory) {
        DataTypes.PurchaseProduct[] memory prodList = productPurchasePool[_pid];
        DataTypes.PurchaseProduct memory _pro;
        for (uint256 i = 0; i < prodList.length; i++) {
            if (
                _customerAddress == prodList[i].customerAddress &&
                _releaseHeight == prodList[i].releaseHeight
            ) {
                _pro = prodList[i];
            }
        }
        return _pro;
    }

    /**
     * Returns DataTypes.PurchaseProduct[]
     * notice 获取指定产品列表
     * @param _pid 产品地址.
     */
    function getProductList(uint256 _pid)
        public
        view
        returns (DataTypes.PurchaseProduct[] memory)
    {
        DataTypes.PurchaseProduct[] memory prodList = productPurchasePool[_pid];
        return prodList;
    }

    /**
     * Returns uint256
     * notice 获取产品买了多少份
     * @param _pid 产品地址.
     */
    function getProductQuantity(uint256 _pid) public view returns (uint256) {
        DataTypes.PurchaseProduct[] memory prodList = productPurchasePool[_pid];
        return prodList.length;
    }

    /**
     * Returns DataTypes.PurchaseProduct[]
     * notice 获取用户获取指定产品数据
     * @param _pid 产品地址.
     * @param _customerAddress 用户钱包地址
     */
    function getUserProducts(uint256 _pid, address _customerAddress)
        external
        view
        returns (DataTypes.PurchaseProduct[] memory)
    {
        DataTypes.PurchaseProduct[]
            memory customerProdList = productPurchasePool[_pid];

        uint256 count;
        for (uint256 i = 0; i < customerProdList.length; i++) {
            if (_customerAddress == customerProdList[i].customerAddress) {
                count++;
            }
        }
        DataTypes.PurchaseProduct[]
            memory list = new DataTypes.PurchaseProduct[](count);
        uint256 j;
        for (uint256 i = 0; i < customerProdList.length; i++) {
            if (_customerAddress == customerProdList[i].customerAddress) {
                list[j] = customerProdList[i];
                j++;
            }
        }
        return list;
    }

    /**
     * Returns bool
     * notice 添加产品
     * @param _pid 产品地址.
     * @param _customerAddress 用户钱包地址
     * @param _amount 金额数量
     * @param _token erc20 币种
     * @param _customerReward 奖励
     * @param _cryptoQuantity 用户最终得到目标币
     */
    function addCustomerByProduct(
        uint256 _pid,
        address _customerAddress,
        uint256 _amount,
        address _token,
        uint256 _customerReward,
        uint256 _cryptoQuantity
    ) external onlyProxy returns (bool) {
        DataTypes.PurchaseProduct memory product = DataTypes.PurchaseProduct({
            customerAddress: _customerAddress,
            amount: _amount,
            releaseHeight: block.number,
            tokenAddress: _token,
            customerReward: _customerReward,
            cryptoQuantity: _cryptoQuantity
        });

        DataTypes.PurchaseProduct[] storage prodList = productPurchasePool[
            _pid
        ];
        prodList.push(product);
        return true;
    }

    /**
     * Returns bool
     * notice 清空指定产品
     * @param _pid 产品地址.
     * @param _customerAddress 用户钱包地址
     * @param _releaseHeight 区块高度
     */
    function deleteSpecifiedProduct(
        uint256 _pid,
        address _customerAddress,
        uint256 _releaseHeight
    ) external onlyProxy returns (bool) {
        DataTypes.PurchaseProduct[] storage prodList = productPurchasePool[
            _pid
        ];
        for (uint256 i = 0; i < prodList.length; i++) {
            if (
                _customerAddress == prodList[i].customerAddress &&
                _releaseHeight == prodList[i].releaseHeight
            ) {
                prodList[i] = prodList[prodList.length - 1];
                prodList.pop();
            }
        }
        return true;
    }
}