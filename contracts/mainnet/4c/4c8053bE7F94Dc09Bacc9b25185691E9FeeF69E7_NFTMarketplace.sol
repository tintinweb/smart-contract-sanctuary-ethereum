/******************************************************************************************************
Yieldification NFT Marketplace

Website: https://yieldification.com
Twitter: https://twitter.com/yieldification
Telegram: https://t.me/yieldification
******************************************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IERC721Royalty.sol';
import './interfaces/IWETH.sol';

contract NFTMarketplace is Ownable {
  using SafeERC20 for IERC20;

  uint256 public constant DENOMENATOR = 10000;

  address public treasury;
  IWETH public weth;
  uint256 public addOfferFee = 1 ether / 1000; // 0.001 ETH
  uint256 public serviceFeePercent = (DENOMENATOR * 2) / 100; // 2%
  // ERC20 token => amount volume
  mapping(address => uint256) public totalVolume;
  // ERC20 token => whether it's valid
  mapping(address => bool) public validOfferERC20;
  address[] _validOfferTokens;
  mapping(address => uint256) _validOfferTokensIdx;

  struct BuyItNowConfig {
    address creator;
    address nftContract;
    uint256 tokenId;
    address erc20;
    uint256 amount;
  }
  mapping(bytes32 => BuyItNowConfig) _buyItNowConfigs;

  struct Offer {
    address owner; // person who created offer
    address nftContract;
    uint256 tokenId;
    address offerERC20;
    uint256 amount;
    uint256 timestamp;
    uint256 expiration;
  }
  // NFT ID => Offer
  mapping(bytes32 => Offer[]) _offers;

  event AddOffer(
    address indexed owner,
    address nftContract,
    uint256 tokenId,
    address offerToken,
    uint256 offerAmount
  );
  event RemoveOffer(
    address indexed owner,
    address nftContract,
    uint256 tokenId,
    uint256 offerIdx
  );
  event EditOffer(
    address indexed owner,
    address nftContract,
    uint256 tokenId,
    uint256 offerIdx,
    uint256 offerAmount,
    uint256 expiration
  );
  event ProcessTransaction(
    address indexed nftContract,
    uint256 tokenId,
    address oldOwner,
    address newOwner,
    address paymentToken,
    uint256 price
  );

  constructor(IWETH _weth) {
    weth = _weth;
  }

  function getAllNFTOffers(address _nftContract, uint256 _tokenId)
    public
    view
    returns (Offer[] memory)
  {
    return _offers[_getUniqueNFTID(_nftContract, _tokenId)];
  }

  function getAllOffersMultiple(
    address _nftContract,
    uint256[] memory _tokenIds
  ) external view returns (Offer[][] memory) {
    Offer[][] memory _allOffers;
    for (uint256 _i = 0; _i < _tokenIds.length; _i++) {
      _allOffers[_i] = getAllNFTOffers(_nftContract, _tokenIds[_i]);
    }
    return _allOffers;
  }

  function getAllValidOfferTokens() external view returns (address[] memory) {
    return _validOfferTokens;
  }

  function getBuyItNowConfig(address _nftContract, uint256 _tokenId)
    external
    view
    returns (BuyItNowConfig memory)
  {
    return _buyItNowConfigs[_getUniqueNFTID(_nftContract, _tokenId)];
  }

  function addBuyItNowConfig(
    address _nftContract,
    uint256 _tokenId,
    address _offerToken,
    uint256 _offerAmount
  ) external {
    require(
      _offerToken == address(0) || validOfferERC20[_offerToken],
      'invalid buy it now token'
    );

    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(_nft.ownerOf(_tokenId) == msg.sender, 'must be NFT owner');
    _buyItNowConfigs[_getUniqueNFTID(_nftContract, _tokenId)] = BuyItNowConfig({
      creator: msg.sender,
      nftContract: _nftContract,
      tokenId: _tokenId,
      erc20: _offerToken,
      amount: _offerAmount
    });
  }

  function buyItNow(
    address _nftContract,
    uint256 _tokenId,
    address _buyItNowToken,
    uint256 _buyItNowAmount
  ) external payable {
    bytes32 _nftId = _getUniqueNFTID(_nftContract, _tokenId);
    BuyItNowConfig memory _binConf = _buyItNowConfigs[_nftId];
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(_binConf.creator == _nft.ownerOf(_tokenId), 'BIN1: bad owner');
    require(_binConf.erc20 == _buyItNowToken, 'BIN2: bad token');
    require(_binConf.amount == _buyItNowAmount, 'BIN3: bad amount');

    (address _royaltyAddress, uint256 _royaltyAmount) = _getRoyaltyInfo(
      _nftContract,
      _binConf.amount
    );
    _processPayment(
      _binConf.erc20,
      _binConf.amount,
      msg.sender,
      _binConf.creator,
      _royaltyAddress,
      _royaltyAmount
    );
    _transferNFT(_nftContract, _tokenId, _binConf.creator, msg.sender);

    emit ProcessTransaction(
      _nftContract,
      _tokenId,
      _binConf.creator,
      msg.sender,
      _binConf.erc20,
      _binConf.amount
    );
  }

  function acceptOffer(
    address _nftContract,
    uint256 _tokenId,
    uint256 _offerIdx,
    address _offerToken,
    uint256 _offerAmount
  ) external {
    Offer memory _offer = _offers[_getUniqueNFTID(_nftContract, _tokenId)][
      _offerIdx
    ];
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(msg.sender == _nft.ownerOf(_tokenId), 'ACCOFF1: must be owner');
    require(_offer.offerERC20 == _offerToken, 'ACCOFF2: bad token');
    require(_offer.amount == _offerAmount, 'ACCOFF3: bad amount');
    require(
      _offer.expiration == 0 || _offer.expiration > block.timestamp,
      'ACCOFF4: expired'
    );

    (address _royaltyAddress, uint256 _royaltyAmount) = _getRoyaltyInfo(
      _nftContract,
      _offer.amount
    );
    _processPayment(
      _offer.offerERC20,
      _offer.amount,
      _offer.owner,
      msg.sender,
      _royaltyAddress,
      _royaltyAmount
    );
    _transferNFT(_nftContract, _tokenId, msg.sender, _offer.owner);
    _removeOffer(_offer.owner, _nftContract, _tokenId, _offerIdx);

    emit ProcessTransaction(
      _nftContract,
      _tokenId,
      msg.sender,
      _offer.owner,
      _offer.offerERC20,
      _offer.amount
    );
  }

  function addOffer(
    address _nftContract,
    uint256 _tokenId,
    address _offerToken,
    uint256 _offerAmount,
    uint256 expiration
  ) external payable {
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    address _finalOfferToken;
    uint256 _finalOfferAmount;

    require(_nft.ownerOf(_tokenId) != msg.sender, 'ADDOFF1: not owner');

    if (_offerToken == address(0)) {
      require(msg.value > addOfferFee, 'ADDOFF2: need ETH');
      require(validOfferERC20[address(weth)], 'ADDOFF3: WETH not valid');

      uint256 _ethOfferAmount = msg.value - addOfferFee;
      IERC20 _wethIERC20 = IERC20(address(weth));
      uint256 _wethBalBefore = _wethIERC20.balanceOf(address(this));
      weth.deposit{ value: _ethOfferAmount }();
      _wethIERC20.transfer(
        msg.sender,
        _wethIERC20.balanceOf(address(this)) - _wethBalBefore
      );

      _finalOfferToken = address(weth);
      _finalOfferAmount = (_ethOfferAmount * 10**weth.decimals()) / 10**18;
    } else {
      require(msg.value == addOfferFee, 'ADDOFF4: offer fee');
      require(validOfferERC20[_offerToken], 'ADDOFF5: invalid offer token');
      _finalOfferToken = _offerToken;
      _finalOfferAmount = _offerAmount;
    }

    if (addOfferFee > 0) {
      (bool _success, ) = payable(_getTreasury()).call{ value: addOfferFee }(
        ''
      );
      require(_success, 'ADDOFF6: add offer fee');
    }

    IERC20 _offTokenCont = IERC20(_finalOfferToken);
    require(
      _offTokenCont.balanceOf(msg.sender) >= _finalOfferAmount,
      'ADDOFF7: bad balance'
    );
    require(
      _offTokenCont.allowance(msg.sender, address(this)) >= _finalOfferAmount,
      'ADDOFF8: need allowance'
    );
    require(expiration == 0 || expiration > block.timestamp, 'bad expiration');

    _offers[_getUniqueNFTID(_nftContract, _tokenId)].push(
      Offer({
        owner: msg.sender,
        nftContract: _nftContract,
        tokenId: _tokenId,
        offerERC20: _finalOfferToken,
        amount: _finalOfferAmount,
        timestamp: block.timestamp,
        expiration: expiration
      })
    );
    emit AddOffer(
      msg.sender,
      _nftContract,
      _tokenId,
      _finalOfferToken,
      _finalOfferAmount
    );
  }

  function editOffer(
    address _nftContract,
    uint256 _tokenId,
    uint256 _offerIdx,
    uint256 _offerAmount,
    uint256 _expiration
  ) external {
    bytes32 _nftId = _getUniqueNFTID(_nftContract, _tokenId);
    Offer storage _offer = _offers[_nftId][_offerIdx];
    require(_offer.owner == msg.sender, 'must own offer to edit');

    if (_offerAmount > 0) {
      _offer.amount = _offerAmount;
    }
    if (_expiration > 0) {
      _offer.expiration = _expiration;
    }

    emit EditOffer(
      _offer.owner,
      _nftContract,
      _tokenId,
      _offerIdx,
      _offerAmount,
      _expiration
    );
  }

  function removeOffer(
    address _nftContract,
    uint256 _tokenId,
    uint256 _offerIdx
  ) external {
    _removeOffer(msg.sender, _nftContract, _tokenId, _offerIdx);
  }

  function _removeOffer(
    address _caller,
    address _nftContract,
    uint256 _tokenId,
    uint256 _offerIdx
  ) internal {
    bytes32 _nftId = _getUniqueNFTID(_nftContract, _tokenId);
    Offer memory _offer = _offers[_nftId][_offerIdx];
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(_offer.owner != address(0), 'offer does not exist');
    require(
      _caller == _offer.owner || _caller == _nft.ownerOf(_tokenId),
      'must be offer or NFT owner to remove'
    );
    _offers[_nftId][_offerIdx] = _offers[_nftId][_offers[_nftId].length - 1];
    _offers[_nftId].pop();

    emit RemoveOffer(_offer.owner, _nftContract, _tokenId, _offerIdx);
  }

  function _getUniqueNFTID(address _nftContract, uint256 _tokenId)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(_nftContract, _tokenId));
  }

  function _processPayment(
    address _paymentToken,
    uint256 _amount,
    address _payor,
    address _receiver,
    address _royaltyReceiver,
    uint256 _royaltyAmount
  ) internal {
    uint256 _amountAfterRoyalty = _amount;
    if (_royaltyReceiver != address(0)) {
      _amountAfterRoyalty -= _royaltyAmount;
    }
    uint256 _treasuryAmount = (_amountAfterRoyalty * serviceFeePercent) /
      DENOMENATOR;
    uint256 _receiverAmount = _amountAfterRoyalty - _treasuryAmount;
    if (_paymentToken == address(0)) {
      require(msg.value >= _amount, 'not enough ETH to pay for NFT');
      uint256 _before = address(this).balance;
      // process royalty payment
      if (_royaltyAmount > 0) {
        (bool _royaltySuccess, ) = payable(_royaltyReceiver).call{
          value: _royaltyAmount
        }('');
        require(_royaltySuccess, 'royalty payment was not processed');
      }
      // process treasury payment
      if (_treasuryAmount > 0) {
        (bool _treasSuccess, ) = payable(_getTreasury()).call{
          value: _treasuryAmount
        }('');
        require(_treasSuccess, 'treasury payment was not processed');
      }
      (bool _success, ) = payable(_receiver).call{ value: _receiverAmount }('');
      require(_success, 'main payment was not processed');
      require(address(this).balance >= _before - _amount);
    } else {
      IERC20 _paymentTokenCont = IERC20(_paymentToken);
      // process royalty payment
      if (_royaltyAmount > 0) {
        _paymentTokenCont.safeTransferFrom(
          _payor,
          _royaltyReceiver,
          _royaltyAmount
        );
      }
      if (_treasuryAmount > 0) {
        _paymentTokenCont.safeTransferFrom(
          _payor,
          _getTreasury(),
          _treasuryAmount
        );
      }
      _paymentTokenCont.safeTransferFrom(_payor, _receiver, _receiverAmount);
    }
    totalVolume[_paymentToken] += _amount;
  }

  function _transferNFT(
    address _nftContract,
    uint256 _tokenId,
    address _oldOwner,
    address _newOwner
  ) internal {
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(_nft.ownerOf(_tokenId) == _oldOwner, 'current owner invalid');
    _nft.safeTransferFrom(_oldOwner, _newOwner, _tokenId);

    // clean up any existing buy it now config
    bytes32 _nftId = _getUniqueNFTID(_nftContract, _tokenId);
    delete _buyItNowConfigs[_nftId];
  }

  function _getRoyaltyInfo(address _nftContract, uint256 _saleAmount)
    internal
    view
    returns (address, uint256)
  {
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    try _nft.royaltyInfo(0, _saleAmount) returns (
      address _royaltyAddress,
      uint256 _royaltyAmount
    ) {
      return (_royaltyAddress, _royaltyAmount);
    } catch {
      return (address(0), 0);
    }
  }

  function _getTreasury() internal view returns (address) {
    return treasury == address(0) ? owner() : treasury;
  }

  function updateValidOfferToken(address _token, bool _isValid)
    external
    onlyOwner
  {
    require(validOfferERC20[_token] != _isValid, 'must toggle');
    validOfferERC20[_token] = _isValid;
    if (_isValid) {
      _validOfferTokensIdx[_token] = _validOfferTokens.length;
      _validOfferTokens.push(_token);
    } else {
      uint256 _idx = _validOfferTokensIdx[_token];
      delete _validOfferTokensIdx[_token];
      _validOfferTokens[_idx] = _validOfferTokens[_validOfferTokens.length - 1];
      _validOfferTokens.pop();
    }
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function setServiceFeePercent(uint256 _percent) external onlyOwner {
    require(_percent <= (DENOMENATOR * 10) / 100, 'must be <= 10%');
    serviceFeePercent = _percent;
  }

  function setAddOfferFee(uint256 _wei) external onlyOwner {
    addOfferFee = _wei;
  }

  function setWETH(IWETH _weth) external onlyOwner {
    weth = _weth;
  }

  function withdrawERC20(address _tokenAddress, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _contract = IERC20(_tokenAddress);
    _amount = _amount == 0 ? _contract.balanceOf(address(this)) : _amount;
    require(_amount > 0);
    _contract.safeTransfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IERC721Royalty is IERC721 {
  // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IWETH {
  function decimals() external view returns (uint8);

  function deposit() external payable;

  function withdraw(uint256 wad) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// SPDX-License-Identifier: MIT
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