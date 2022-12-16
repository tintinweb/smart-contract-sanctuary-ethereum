/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// File: yomiswap/interfaces/IRouter.sol


pragma solidity =0.8.17;

interface IRouter {
    function getIsCollectionApprove(address collection) external returns (bool);

    function getIsBondingCurveApprove(address bondingCurve)
        external
        returns (bool);

    function getIsPaymentTokenApprove(address paymentToken)
        external
        view
        returns (bool);

    function setPool(address _pool, bool _approve) external;
}

// File: yomiswap/bonding-curves/CurveErrorCode.sol


pragma solidity =0.8.17;

contract CurveErrorCodes {
    //@notice OK: No Error
    //@notice INVALID_NUMITEMS: The numItem value is 0
    //@notice SPOT_PRICE_OVERFLOW: The updated spot price doesn't fit into 128 bits
    enum Error {
        OK,
        INVALID_NUMITEMS,
        SPOT_PRICE_OVERFLOW
    }
}

// File: yomiswap/interfaces/ICurve.sol


pragma solidity =0.8.17;


interface ICurve {
    function getBuyInfo(
        uint256 spotPrice,
        uint256 delta,
        uint256 divergence,
        uint256 numItems
    )
        external
        pure
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 newDivergence,
            uint256 totalFee
        );

    function getSellInfo(
        uint256 spotPrice,
        uint256 delta,
        uint256 divergence,
        uint256 numItems
    )
        external
        pure
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 newDivergence,
            uint256 totalFee
        );

    function getBuyFeeInfo(
        uint256 spotPrice,
        uint256 delta,
        uint256 spread,
        uint256 numItems,
        uint256 protocolFeeRatio
    ) external pure returns (uint256 lpFee, uint256 protocolFee);

    function getSellFeeInfo(
        uint256 spotPrice,
        uint256 delta,
        uint256 spread,
        uint256 numItems,
        uint256 protocolFeeRatio
    ) external pure returns (uint256 lpFee, uint256 protocolFee);

    function getFee(
        uint256 totalFee,
        uint256 spread,
        uint256 protocolFeeRatio
    ) external pure returns (uint256 lpFee, uint256 protocolFee);
}

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: yomiswap/src/BasePool.sol


pragma solidity =0.8.17;



contract BasePool {
    //@param E18
    uint256 E18 = 1e18;

    //@param bondingCurve: bondingCurve for change buyPrice and sellPrice
    address public bondingCurve;

    //@param collection: only collection address'tokenIds to this pool
    address public collection;

    //@param router: address of router
    address public router;

    //@param owner: creater of this pool
    address public owner;

    //@param paymentToken: use only this address ERC20 or Native
    address public paymentToken;

    //@param protocolFeeRatio: default under 10%
    uint256 public protocolFeeRatio;

    //@param BuyEventNum: num of buyEvent
    uint256 public buyEventNum;

    //@param SellEventNum: num of sellEvent
    uint256 public sellEventNum;

    //@param stakeNFTprice: price of spot staking NFT
    uint256 public stakeNFTprice;

    //@param stakeFTprice: price of spot staking FT
    uint256 public stakeFTprice;

    //@param isOtherStake: flg of other staking
    bool public isOtherStake;

    //@param isPair: flg of pair
    bool public isPair;

    //@param holdIds: this address hold TokenIds
    uint256[] public holdIds;

    //@param poolInfo: information of this pool
    PoolInfo public poolInfo;

    //@param PoolInfo: struct of Pool
    struct PoolInfo {
        uint256 spotPrice;
        uint256 delta;
        uint256 spread;
        uint256 buyNum;
        uint256 sellNum;
    }

    //@param UserInfo: struct of user
    struct UserInfo {
        uint256 initBuyNum;
        uint256 initSellNum;
        uint256 initSellAmount;
        uint256 totalNFTpoint;
        uint256 totalFTpoint;
        uint256 totalNFTprice;
    }

    //@notice only router address
    modifier onlyRouter() {
        require(router == msg.sender, "onlyRouter");
        _;
    }

    //INTERNAL
    //@notice batch nft transfer
    function _sendNFTs(
        uint256[] calldata _tokenIds,
        uint256 _itemNum,
        address _from,
        address _to
    ) internal {
        unchecked {
            for (uint256 i = 0; i < _itemNum; i++) {
                IERC721(collection).safeTransferFrom(
                    _from,
                    _to,
                    _tokenIds[i],
                    ""
                );
            }
        }
        if (_from == address(this)) {
            _removeHoldIds(_tokenIds);
        } else if (_to == address(this)) {
            _addHoldIds(_tokenIds);
        }
    }

    //@notice update poolInfo
    function _updatePoolInfo(
        uint256 _newSpotPrice,
        uint256 _newDelta,
        uint256 _newSpread
    ) internal {
        if (_newSpotPrice != 0 && poolInfo.spotPrice != _newSpotPrice) {
            poolInfo.spotPrice = _newSpotPrice;
        }
        if (_newDelta != 0 && poolInfo.delta != _newDelta) {
            poolInfo.delta = _newDelta;
        }
        if (_newSpread != 0 && poolInfo.spread != _newSpread) {
            poolInfo.spread = _newSpread;
        }
    }

    //@notice update stakeFTprice
    function _updateStakeFTInfo(
        uint256 _newStakeFTPrice,
        uint256 _newDelta,
        uint256 _newSpread
    ) internal {
        if (_newStakeFTPrice != 0 && stakeFTprice != _newStakeFTPrice) {
            stakeFTprice = _newStakeFTPrice;
        }
        if (_newDelta != 0 && poolInfo.delta != _newDelta) {
            poolInfo.delta = _newDelta;
        }
        if (_newSpread != 0 && poolInfo.spread != _newSpread) {
            poolInfo.spread = _newSpread;
        }
    }

    //@notice update stakeNFTprice
    function _updateStakeNFTInfo(
        uint256 _newStakeNFTPrice,
        uint256 _newDelta,
        uint256 _newSpread
    ) internal {
        if (_newStakeNFTPrice != 0 && stakeNFTprice != _newStakeNFTPrice) {
            stakeNFTprice = _newStakeNFTPrice;
        }
        if (_newDelta != 0 && poolInfo.delta != _newDelta) {
            poolInfo.delta = _newDelta;
        }
        if (_newSpread != 0 && poolInfo.spread != _newSpread) {
            poolInfo.spread = _newSpread;
        }
    }

    //@notice add tokenId to list hold token
    function _addHoldIds(uint256[] calldata _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            holdIds.push(_tokenIds[i]);
        }
    }

    //@notice remove tokenId to list hold token
    function _removeHoldIds(uint256[] calldata _tokenIds) internal {
        for (uint256 j = 0; j < _tokenIds.length; j++) {
            uint256 _num = holdIds.length;
            for (uint256 i = 0; i < _num; i++) {
                if (holdIds[i] == _tokenIds[j]) {
                    if (i != _num - 1) {
                        holdIds[i] = holdIds[_num - 1];
                    }
                    holdIds.pop();
                    break;
                }
            }
        }
    }

    //GET
    //@notice get pool info
    function getPoolInfo() external view returns (PoolInfo memory) {
        return poolInfo;
    }

    //@notice get all tokenIds
    function getAllHoldIds() external view returns (uint256[] memory) {
        return holdIds;
    }

    //@notice calculation total buy price
    function getCalcBuyInfo(uint256 _itemNum, uint256 _spotPrice)
        external
        view
        returns (uint256)
    {
        (, , , , uint256 _totalFee) = ICurve(bondingCurve).getBuyInfo(
            _spotPrice,
            poolInfo.delta,
            poolInfo.spread,
            _itemNum
        );
        return _totalFee;
    }

    //@notice calculation total sell price
    function getCalcSellInfo(uint256 _itemNum, uint256 _spotPrice)
        external
        view
        returns (uint256)
    {
        (, , , , uint256 _totalFee) = ICurve(bondingCurve).getSellInfo(
            _spotPrice,
            poolInfo.delta,
            poolInfo.spread,
            _itemNum
        );
        return _totalFee;
    }

    //SET
    //@notice set of Router address
    function setRouter(address _newRouter) external onlyRouter {
        router = _newRouter;
    }

    //@notice set of protocolFee ratio
    function setProtocolFeeRatio(uint256 _newProtocolFeeRatio)
        external
        onlyRouter
    {
        protocolFeeRatio = _newProtocolFeeRatio;
    }

    //RECEIVED
    //@notice receive関数
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: yomiswap/src/NonOtherPool.sol


pragma solidity =0.8.17;


contract NonOtherPool is BasePool {
    //@param totalFee: totalFee of userFee
    uint256 public totalFee;

    //@param userInfo: owner's userInfo
    UserInfo public userInfo;

    //@param
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyNotOtherStake(address _user) {
        require(msg.sender == router, "Not Router");
        require(_user == owner, "Not Owner");
        _;
    }

    //@notice calc profit
    function _calcBuyProfit() internal returns (uint256) {
        if (buyEventNum > 0 && sellEventNum > 0 && buyEventNum >= sellEventNum) {
            (uint256 lpFee, uint256 protocolFee) = ICurve(bondingCurve)
                .getBuyFeeInfo(
                    poolInfo.spotPrice,
                    poolInfo.delta,
                    poolInfo.spread,
                    sellEventNum,
                    protocolFeeRatio
                );
            totalFee = lpFee;
            buyEventNum -= sellEventNum;
            sellEventNum = 0;
            return protocolFee;
        }
    }

    function _calcSellProfit() internal returns(uint256){
        if (buyEventNum > 0 && sellEventNum > 0 && sellEventNum >= buyEventNum) {
            (uint256 lpFee, uint256 protocolFee) = ICurve(bondingCurve)
                .getSellFeeInfo(
                    poolInfo.spotPrice,
                    poolInfo.delta,
                    poolInfo.spread,
                    buyEventNum,
                    protocolFeeRatio
                );
            totalFee = lpFee;
            sellEventNum -= buyEventNum;
            buyEventNum = 0;
            return protocolFee;
        }
    }

    //GET
    //@notice get userInfo of userInfo
    function getUserInfo() external view returns (UserInfo memory) {
        return userInfo;
    }

    //SET
    //@notice set newSpotPrice
    function setSpotPrice(uint256 _newSpotPrice) external onlyOwner {
        poolInfo.spotPrice = _newSpotPrice;
    }

    //@notice set newDelta
    function setDelta(uint256 _newDelta) external onlyOwner {
        poolInfo.delta = _newDelta;
    }

    //@notice set newSpread
    function setSpread(uint256 _newSpread) external onlyOwner {
        poolInfo.spread = _newSpread;
    }
}

// File: yomiswap/src/NativeNOPool.sol


pragma solidity =0.8.17;


contract NativeNOPool is NonOtherPool {
    //@notice swap FT for NFT
    function swapFTforNFT(uint256[] calldata _tokenIds, address _user)
        external
        payable
        onlyRouter
        returns (uint256 _protocolFee)
    {
        uint256 _itemNum = _tokenIds.length;

        //calc total fee
        (
            CurveErrorCodes.Error error,
            uint256 _newSpotPrice,
            uint256 _newDelta,
            uint256 _newDivergence,
            uint256 _totalFee
        ) = ICurve(bondingCurve).getBuyInfo(
                poolInfo.spotPrice,
                poolInfo.delta,
                poolInfo.spread,
                _itemNum
            );
        require(error == CurveErrorCodes.Error.OK, "BC Error");

        //check
        require(_itemNum <= poolInfo.buyNum, "Not enough liquidity");
        require(msg.value >= _totalFee, "Not enough value");

        //effect
        buyEventNum += _itemNum;
        poolInfo.buyNum -= _itemNum;
        poolInfo.sellNum += _itemNum;
        _protocolFee = _calcSellProfit();
        _updatePoolInfo(_newSpotPrice, _newDelta, _newDivergence);

        //intaraction
        payable(_user).transfer(msg.value - _totalFee);
        if (_protocolFee > 0) {
            payable(router).transfer(_protocolFee);
        }
        _sendNFTs(_tokenIds, _tokenIds.length, address(this), _user);
    }

    //@notice swap NFT for FT
    function swapNFTforFT(
        uint256[] calldata _tokenIds,
        uint256 _minExpectFee,
        address _user
    ) external payable onlyRouter returns (uint256 _protocolFee) {
        uint256 _itemNum = _tokenIds.length;

        //calc total fee
        (
            CurveErrorCodes.Error error,
            uint256 _newSpotPrice,
            uint256 _newDelta,
            uint256 _newDivergence,
            uint256 _totalFee
        ) = ICurve(bondingCurve).getSellInfo(
                poolInfo.spotPrice,
                poolInfo.delta,
                poolInfo.spread,
                _itemNum
            );
        require(error == CurveErrorCodes.Error.OK, "BC Error");

        //check
        require(_itemNum <= poolInfo.sellNum, "Not enough liquidity");
        require(_totalFee >= _minExpectFee, "Not expected value");
        require(address(this).balance >= _totalFee, "Not enough balance");

        //effect
        sellEventNum += _itemNum;
        poolInfo.sellNum -= _itemNum;
        poolInfo.buyNum += _itemNum;
        _protocolFee = _calcBuyProfit();
        _updatePoolInfo(_newSpotPrice, _newDelta, _newDivergence);

        //intaraction
        payable(_user).transfer(_totalFee);
        if (_protocolFee > 0) {
            payable(router).transfer(_protocolFee);
        }
        _sendNFTs(_tokenIds, _itemNum, _user, address(this));
    }
}

// File: yomiswap/pool/SingleNativeNOPool.sol


pragma solidity =0.8.17;


contract SingleNativeNOPool is NativeNOPool {
    constructor(
        address _collection,
        address _bondingCurve,
        uint256 _spotPrice,
        uint256 _delta,
        uint256 _spread,
        uint256 _protocolFeeRatio,
        address _router,
        address _creater
    ) {
        collection = _collection;
        bondingCurve = _bondingCurve;
        poolInfo.spotPrice = _spotPrice;
        stakeNFTprice = _spotPrice;
        stakeFTprice = _spotPrice;
        poolInfo.delta = _delta;
        poolInfo.spread = _spread;
        protocolFeeRatio = _protocolFeeRatio;
        router = _router;
        isOtherStake = false;
        isPair = false;
        paymentToken = address(0);
        owner = _creater;
    }

    //@notice Stake Native Token
    function stakeFT(uint256 _itemNum, address _user)
        external
        payable
        onlyNotOtherStake(_user)
    {
        require(_itemNum > 0, "Not 0");

        //update stakeFTprice
        (
            CurveErrorCodes.Error error,
            uint256 _newstakeFTprice,
            uint256 _newDelta,
            ,
            uint256 _totalFee
        ) = ICurve(bondingCurve).getSellInfo(
                stakeFTprice,
                poolInfo.delta,
                poolInfo.spread,
                _itemNum
            );
        require(error == CurveErrorCodes.Error.OK, "BC Error");

        //check
        require(msg.value >= _totalFee, "Insufficient Value");

        //effect
        userInfo.initSellNum += _itemNum;
        userInfo.initSellAmount += _totalFee;
        poolInfo.sellNum += _itemNum;
        _updateStakeFTInfo(_newstakeFTprice, _newDelta, 0);
    }

    //@notice Stake NFT
    function stakeNFT(uint256[] calldata _tokenIds, address _user)
        external
        onlyNotOtherStake(_user)
    {
        uint256 _itemNum = _tokenIds.length;
        require(_itemNum > 0, "Not 0");

        //update stakeNFTprice
        (
            CurveErrorCodes.Error error,
            uint256 _newstakeNFTprice,
            uint256 _newDelta,
            ,

        ) = ICurve(bondingCurve).getBuyInfo(
                stakeNFTprice,
                poolInfo.delta,
                poolInfo.spread,
                _itemNum
            );
        require(error == CurveErrorCodes.Error.OK, "BC Error");

        //effect
        userInfo.initBuyNum += _itemNum;
        poolInfo.buyNum += _itemNum;
        _updateStakeNFTInfo(_newstakeNFTprice, _newDelta, 0);

        //intaraction
        _sendNFTs(_tokenIds, _itemNum, _user, address(this));
    }

    //@notice withdraw Native Token
    function withdrawFT(
        uint256 _userSellNum,
        uint256[] calldata _tokenIds,
        address _user
    ) external payable onlyNotOtherStake(_user) returns(uint256 _userFee) {
        uint256 _itemNum = _tokenIds.length;
        uint256 _fee;

        //check
        require(poolInfo.sellNum >= _userSellNum, "Pool not enough NFT");
        require(
            userInfo.initSellNum == _userSellNum || userInfo.initSellNum > _userSellNum &&
                poolInfo.sellNum == _userSellNum,
            "Select Num is Wrong"
        );
        require(userInfo.initSellNum - _userSellNum == _itemNum, "true");

        //effect
        poolInfo.sellNum -= _userSellNum;


        //up stakeFTprice
        if (_userSellNum != 0) {
            (
                CurveErrorCodes.Error error,
                uint256 _newstakeFTprice,
                uint256 _newDelta,
                ,

            ) = ICurve(bondingCurve).getBuyInfo(
                    stakeFTprice,
                    poolInfo.delta,
                    0,
                    _userSellNum
                );
            require(error == CurveErrorCodes.Error.OK, "BC Error");

            _updateStakeFTInfo(_newstakeFTprice, _newDelta, 0);
        }

        //if pool not liquidity FT
        {
            uint256 _userNum = userInfo.initSellNum;
            userInfo.initSellNum = 0;
            if (_userSellNum < _userNum) {
                (
                    CurveErrorCodes.Error error,
                    ,
                    ,
                    ,
                    uint256 _totalCost
                ) = ICurve(bondingCurve).getBuyInfo(
                        stakeFTprice,
                        poolInfo.delta,
                        0,
                        (_userNum - _userSellNum)
                    );
                require(error == CurveErrorCodes.Error.OK, "BC Error");

                (
                    CurveErrorCodes.Error updateError,
                    uint256 _newstakeNFTprice,
                    ,
                    ,

                ) = ICurve(bondingCurve).getSellInfo(
                        stakeNFTprice,
                        poolInfo.delta,
                        0,
                        _itemNum
                    );
                require(updateError == CurveErrorCodes.Error.OK, "BC Error");

                poolInfo.buyNum -= _itemNum;
                sellEventNum -= _itemNum;

                _updateStakeNFTInfo(_newstakeNFTprice, 0, 0);

                _fee = _totalCost;
            }
        }

        {
            _userFee = totalFee;
            uint256 _userSellAmount = userInfo.initSellAmount;
            userInfo.initSellAmount = 0;
            totalFee = 0;
            if (_userFee > 0) {
                payable(_user).transfer(_userFee);
            }
            if (_fee < _userSellAmount) {
                payable(_user).transfer(_userSellAmount - _fee);
            }
        }
        if (_itemNum > 0) {
            _sendNFTs(_tokenIds, _itemNum, address(this), _user);
        }
    }

    //@notice withdraw NFT
    function withdrawNFT(uint256[] calldata _tokenIds, address _user)
        external
        payable
        onlyNotOtherStake(_user)returns(uint256 _userFee)
    {
        uint256 _itemNum = _tokenIds.length;
        uint256 _userNum = userInfo.initBuyNum;
        _userFee = totalFee;

        //check
        require(poolInfo.buyNum >= _itemNum, "Pool not enough NFT");
        require(
            _userNum == _itemNum || _userNum > _itemNum && poolInfo.buyNum == _itemNum,
            "Something is wrong."
        );

        //effect
        poolInfo.buyNum -= _itemNum;
        userInfo.initBuyNum = 0;
        totalFee = 0;

        //down stakeNFTprice
        if (_itemNum > 0) {
            (
                CurveErrorCodes.Error errorStakeNFTprice,
                uint256 _newstakeNFTprice,
                uint256 _newDelta,
                ,

            ) = ICurve(bondingCurve).getSellInfo(
                    stakeNFTprice,
                    poolInfo.delta,
                    0,
                    _userNum
                );
            require(errorStakeNFTprice == CurveErrorCodes.Error.OK, "BC Error");

            _updateStakeNFTInfo(_newstakeNFTprice, _newDelta, 0);
        }

        //if pool have not liquidity NFT
        if (_userNum > _itemNum) {
            uint256 _subItemNum = _userNum - _itemNum;

            //calc FT instead NFT
            (
                CurveErrorCodes.Error errorStakeNFTprice,
                ,
                ,
                ,
                uint256 _totalInsteadFee
            ) = ICurve(bondingCurve).getSellInfo(
                    stakeNFTprice,
                    poolInfo.delta,
                    0,
                    _subItemNum
                );
            require(errorStakeNFTprice == CurveErrorCodes.Error.OK, "BC Error");

            //up stakeFTprice
            (
                CurveErrorCodes.Error errorStakeFTprice,
                uint256 _newstakeFTprice,
                uint256 _newDelta,
                ,

            ) = ICurve(bondingCurve).getBuyInfo(
                    stakeFTprice,
                    poolInfo.delta,
                    0,
                    _subItemNum
                );
            require(errorStakeFTprice == CurveErrorCodes.Error.OK, "BC Error");

            _updateStakeFTInfo(_newstakeFTprice, _newDelta, 0);

            poolInfo.sellNum -= _subItemNum;
            buyEventNum -= _subItemNum;

            if (_totalInsteadFee > 0) {
                payable(_user).transfer(_totalInsteadFee);
            }
        }

        //intaraction
        _sendNFTs(_tokenIds, _itemNum, address(this), _user);

        if (_userFee > 0) {
            payable(_user).transfer(_userFee);
        }
    }

    //@notice withdraw part NFT
    function withdrawNFTpart(uint256[] calldata _tokenIds, address _user) external onlyNotOtherStake(_user) {
      uint256 _itemNum = _tokenIds.length;
      //check
      require(_itemNum > 0,"Not 0");
      require(poolInfo.buyNum >= _itemNum, "Pool Not Liquidity");
      require(userInfo.initBuyNum >= _itemNum, "Not so match Staking");

      //effect
      poolInfo.buyNum -= _itemNum;
      userInfo.initBuyNum -= _itemNum;
      
      (
          CurveErrorCodes.Error errorStakeNFTprice,
          uint256 _newstakeNFTprice,
          uint256 _newDelta,
          ,
      ) = ICurve(bondingCurve).getSellInfo(
              stakeNFTprice,
              poolInfo.delta,
              0,
              _itemNum
          );
      require(errorStakeNFTprice == CurveErrorCodes.Error.OK, "BC Error");
      _updateStakeNFTInfo(_newstakeNFTprice, _newDelta, 0);

      //interaction
      _sendNFTs(_tokenIds, _itemNum, address(this), _user);
    }

    //@notice withdraw part FT
    function withdrawFTpart(uint256 _userSellNum, address _user) external onlyNotOtherStake(_user) {
      //check
      require(_userSellNum > 0, "Not 0");
      require(poolInfo.sellNum >= _userSellNum, "Pool Not Liquidity");
      require(userInfo.initSellNum >= _userSellNum, "Not so match Staking");

      //effect
      (
          CurveErrorCodes.Error error,
          uint256 _newstakeFTprice,
          uint256 _newDelta,
          ,
          uint256 _totalFee
      ) = ICurve(bondingCurve).getBuyInfo(
              stakeFTprice,
              poolInfo.delta,
              0,
              _userSellNum
          );
      require(error == CurveErrorCodes.Error.OK, "BC Error");
      _updateStakeFTInfo(_newstakeFTprice, _newDelta, 0);
      poolInfo.sellNum -= _userSellNum;
      userInfo.initSellNum -= _userSellNum;
      userInfo.initSellAmount -= _totalFee; 
    
      //intaraction
      payable(msg.sender).transfer(_totalFee);
    }

    //@notice withdraw fee
    function withdrawFee(address _user)
        external
        payable
        onlyNotOtherStake(_user)
    {
        uint256 _totalFee = totalFee;

        //check
        require(_totalFee > 0);

        //effect
        totalFee = 0;

        //intaraction
        payable(_user).transfer(_totalFee);
    }

    //@notice get user stake fee
    function getUserStakeFee() external view returns (uint256) {
        return totalFee;
    }
}

// File: yomiswap/factory/FactorySingleNativeNOPool.sol


pragma solidity =0.8.17;





contract FactorySingleNativeNOPool is Ownable {
    address public router;
    uint256 public routerFeeRatio;

    //CONSTRCTOR
    constructor(address _router, uint256 _routerFeeRatio) {
        router = _router;
        routerFeeRatio = _routerFeeRatio;
    }

    //EVENT
    event CreatePool(address indexed pool, address indexed collection);

    //MAIN
    function createPool(
        address _collection,
        address _bondingCurve,
        uint256 _spotPrice,
        uint256 _delta,
        uint256 _spread
    ) external {
        require(
            IERC165(_collection).supportsInterface(type(IERC721).interfaceId),
            "OnlyERC721"
        );
        require(IRouter(router).getIsCollectionApprove(_collection) == true);
        require(
            IRouter(router).getIsBondingCurveApprove(_bondingCurve) == true
        );

        address _pool = address(
            new SingleNativeNOPool(
                _collection,
                _bondingCurve,
                _spotPrice,
                _delta,
                _spread,
                routerFeeRatio,
                router,
                msg.sender
            )
        );
        IRouter(router).setPool(_pool, true);
        emit CreatePool(_pool, _collection);
    }

    //SET
    function setRouterAddress(address _newRouter) public onlyOwner {
        router = _newRouter;
    }

    function setRouterFeeRatio(uint256 _newRouterFeeRatio) public onlyOwner {
        routerFeeRatio = _newRouterFeeRatio;
    }
}