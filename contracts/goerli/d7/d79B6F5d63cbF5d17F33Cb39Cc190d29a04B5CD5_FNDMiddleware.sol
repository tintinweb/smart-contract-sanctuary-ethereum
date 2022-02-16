/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;



import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "./FNDNFTMarket.sol";
import "./PercentSplitETH.sol";
import "./CollectionContract.sol";
import "./mixins/Constants.sol";
import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import { ReverseRegistrar } from "@ensdomains/ens-contracts/contracts/registry/ReverseRegistrar.sol";
import { PublicResolver } from "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";

contract FNDMiddleware is Constants {
  using AddressUpgradeable for address;

  struct Fee {
    uint256 percentInBasisPoints;
    uint256 amountInWei;
  }
  struct FeeWithRecipient {
    uint256 percentInBasisPoints;
    uint256 amountInWei;
    address payable recipient;
  }
  struct RevSplit {
    uint256 relativePercentInBasisPoints;
    uint256 absolutePercentInBasisPoints;
    uint256 amountInWei;
    address payable recipient;
  }

  FNDNFTMarket private immutable market;
  FETH private immutable feth;
  ENS private immutable ens;

  constructor(
    address payable _market,
    address payable _feth,
    address _ens
  ) {
    market = FNDNFTMarket(_market);
    feth = FETH(_feth);
    ens = ENS(_ens);
  }

  // solhint-disable-next-line code-complexity
  function getFees(
    address nftContract,
    uint256 tokenId,
    uint256 price
  )
    external
    view
    returns (
      FeeWithRecipient memory foundation,
      Fee memory creator,
      FeeWithRecipient memory owner,
      RevSplit[] memory creatorRevSplit
    )
  {
    foundation.recipient = market.getFoundationTreasury();
    uint256 creatorRev;
    {
      uint256 foundationFee;
      uint256 ownerRev;
      (foundationFee, creatorRev, ownerRev) = market.getFees(nftContract, tokenId, price);
      foundation.amountInWei = foundationFee;
      creator.amountInWei = creatorRev;
      owner.amountInWei = ownerRev;
    }
    uint256 creatorRevBP;
    {
      uint256 foundationFeeBP;
      uint256 ownerRevBP;
      (foundationFeeBP, creatorRevBP, ownerRevBP) = market.getFees(nftContract, tokenId, BASIS_POINTS);
      foundation.percentInBasisPoints = foundationFeeBP;
      creator.percentInBasisPoints = creatorRevBP;
      owner.percentInBasisPoints = ownerRevBP;
    }
    address payable[] memory creatorRecipients;
    uint256[] memory creatorShares;
    {
      address payable ownerAddress;
      (creatorRecipients, creatorShares, ownerAddress) = market.getFeeRecipients(nftContract, tokenId);
      owner.recipient = ownerAddress;
      if (creatorShares.length == 0) {
        creatorShares = new uint256[](creatorRecipients.length);
        if (creatorShares.length == 1) {
          creatorShares[0] = BASIS_POINTS;
        }
      }
    }

    // Normalize shares to 10%
    {
      uint256 totalShares = 0;
      for (uint256 i = 0; i < creatorShares.length; i++) {
        // TODO handle ignore if > 100% (like the market would)
        totalShares += creatorShares[i];
      }

      for (uint256 i = 0; i < creatorShares.length; i++) {
        creatorShares[i] = (BASIS_POINTS * creatorShares[i]) / totalShares;
      }
    }

    {
      // Count creators and split recipients
      uint256 creatorCount = creatorRecipients.length;

      for (uint256 i = 0; i < creatorRecipients.length; i++) {
        // Check if the address is a percent split
        if (address(creatorRecipients[i]).isContract()) {
          try PercentSplitETH(creatorRecipients[i]).getShareLength{ gas: READ_ONLY_GAS_LIMIT }() returns (
            uint256 recipientCount
          ) {

            creatorCount += recipientCount - 1;
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Not a Foundation percent split
          }
        }
      }

      creatorRevSplit = new RevSplit[](creatorCount);
    }

    // Populate rev splits, including any percent splits
    uint256 revSplitIndex = 0;
    for (uint256 i = 0; i < creatorRecipients.length; i++) {
      if (address(creatorRecipients[i]).isContract()) {
        try PercentSplitETH(creatorRecipients[i]).getShareLength{ gas: READ_ONLY_GAS_LIMIT }() returns (
          uint256 recipientCount
        ) {
          uint256 totalSplitShares;
          for (uint256 splitIndex = 0; splitIndex < recipientCount; splitIndex++) {
            uint256 share = PercentSplitETH(creatorRecipients[i]).getPercentInBasisPointsByIndex(splitIndex);
            totalSplitShares += share;
          }
          for (uint256 splitIndex = 0; splitIndex < recipientCount; splitIndex++) {
            uint256 splitShare = (PercentSplitETH(creatorRecipients[i]).getPercentInBasisPointsByIndex(splitIndex) *
              BASIS_POINTS) / totalSplitShares;
            splitShare = (splitShare * creatorShares[i]) / BASIS_POINTS;
            creatorRevSplit[revSplitIndex++] = _calcRevSplit(
              price,
              splitShare,
              creatorRevBP,
              PercentSplitETH(creatorRecipients[i]).getShareRecipientByIndex(splitIndex)
            );
          }
          continue;
        } catch // solhint-disable-next-line no-empty-blocks
        {
          // Not a Foundation percent split
        }
      }
      {
        creatorRevSplit[revSplitIndex++] = _calcRevSplit(price, creatorShares[i], creatorRevBP, creatorRecipients[i]);
      }
    }
  }

  function getAccountInfo(address account)
    external
    view
    returns (
      uint256 ethBalance,
      uint256 availableFethBalance,
      uint256 lockedFethBalance,
      string memory ensName
    )
  {
    ethBalance = account.balance;
    availableFethBalance = feth.balanceOf(account);
    lockedFethBalance = feth.totalBalanceOf(account) - availableFethBalance;

    // Lookup ENS name, if one was registered
    ReverseRegistrar reverseRegistrar = ReverseRegistrar(ens.owner(
      keccak256(
        abi.encodePacked(
          keccak256(
            abi.encodePacked(abi.encode(bytes32(0)), keccak256("reverse"))
          ),
          keccak256("addr")
        )
      )
    ));
    bytes32 node = reverseRegistrar.node(account);
    if (node != bytes32(0)) {
      address resolver = ens.resolver(node);
      ensName = PublicResolver(resolver).name(node);
    }
  }

  function _calcRevSplit(
    uint256 price,
    uint256 share,
    uint256 creatorRevBP,
    address payable recipient
  ) private pure returns (RevSplit memory) {
    uint256 absoluteShare = (share * creatorRevBP) / BASIS_POINTS;
    uint256 amount = (absoluteShare * price) / BASIS_POINTS;
    return RevSplit(share, absoluteShare, amount, recipient);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./mixins/FoundationTreasuryNode.sol";
import "./mixins/roles/FoundationAdminRole.sol";
import "./mixins/roles/FoundationOperatorRole.sol";
import "./mixins/NFTMarketCore.sol";
import "./mixins/SendValueWithFallbackWithdraw.sol";
import "./mixins/NFTMarketCreators.sol";
import "./mixins/NFTMarketFees.sol";
import "./mixins/NFTMarketAuction.sol";
import "./mixins/NFTMarketReserveAuction.sol";
import "./mixins/NFTMarketPrivateSale.sol";
import "./mixins/NFTMarketBuyNow.sol";
import "./mixins/NFTMarketOffer.sol";

/**
 * @title A market for NFTs on Foundation.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract FNDNFTMarket is
  FoundationTreasuryNode,
  FoundationAdminRole,
  FoundationOperatorRole,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  NFTMarketCreators,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction,
  NFTMarketReserveAuction,
  NFTMarketPrivateSale,
  NFTMarketBuyNow,
  NFTMarketOffer
{
  constructor(
    address payable treasury,
    address feth,
    address royaltyRegistry,
    uint256 duration,
    address proxyAddress
  )
    FoundationTreasuryNode(treasury)
    NFTMarketCore(feth)
    NFTMarketCreators(royaltyRegistry)
    NFTMarketReserveAuction(duration)
    NFTMarketPrivateSale(proxyAddress) // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This farms the initialize call out to inherited contracts as needed.
   */
  function initialize() external initializer {
    NFTMarketAuction._initializeNFTMarketAuction();
  }

  /**
   * @dev Checks who the seller for an NFT is, this will check escrow or return the current owner if not in escrow.
   * This is a no-op function required to avoid compile errors.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyNow)
    returns (address payable)
  {
    return super._getSellerFor(nftContract, tokenId);
  }

  /**
   * @dev Notify implementors of _auctionStarted on auction kick-off.
   * This is a no-op function required to avoid compile errors.
   */
  function _auctionStarted(address nftContract, uint256 tokenId)
    internal
    virtual
    override(NFTMarketCore, NFTMarketBuyNow, NFTMarketOffer)
  {
    super._auctionStarted(nftContract, tokenId);
  }

  /**
   * @dev Notify implementors of _offerAccepted when an offer in escrow is accepted.
   * This is a no-op function required to avoid compile errors.
   */
  function _offerAccepted(address nftContract, uint256 tokenId)
    internal
    virtual
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyNow)
  {
    super._offerAccepted(nftContract, tokenId);
  }

  /**
   * @dev Notify implementors of _buyNowPriceMet when an NFT is sold with BuyNow.
   * This is a no-op function required to avoid compile errors.
   */
  function _buyNowPriceMet(
    address nftContract,
    uint256 tokenId,
    address buyer
  ) internal virtual override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketOffer) {
    super._buyNowPriceMet(nftContract, tokenId, buyer);
  }
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20Approve.sol";
import "./libraries/BytesLibrary.sol";

/**
 * @notice Deploys contracts which auto-forwards any ETH sent to it to a list of recipients
 * considering their percent share of the payment received.
 * @dev Uses create2 counterfactual addresses so that the destination is known from the terms of the split.
 */
contract PercentSplitETH is Initializable {
  using AddressUpgradeable for address payable;
  using AddressUpgradeable for address;
  using BytesLibrary for bytes;
  using SafeMath for uint256;

  struct Share {
    address payable recipient;
    uint16 percentInBasisPoints;
  }

  uint256 private constant BASIS_POINTS = 10000;

  Share[] private _shares;

  event PercentSplitCreated(address indexed contractAddress);
  event PercentSplitShare(address indexed recipient, uint256 percentInBasisPoints);
  event ETHTransferred(address indexed account, uint256 amount);
  event ERC20Transferred(address indexed erc20Contract, address indexed account, uint256 amount);

  /**
   * @dev Requires that the msg.sender is one of the recipients in this split.
   */
  modifier onlyRecipient() {
    for (uint256 i = 0; i < _shares.length; i++) {
      if (_shares[i].recipient == msg.sender) {
        _;
        return;
      }
    }
    revert("Split: Can only be called by one of the recipients");
  }

  /**
   * @notice Creates a new minimal proxy contract and initializes it with the given split terms.
   * If the contract had already been created, its address is returned.
   * This must be called on the original implementation and not a proxy created previously.
   */
  function createSplit(Share[] memory shares) external returns (PercentSplitETH splitInstance) {
    bytes32 salt = keccak256(abi.encode(shares));
    address clone = Clones.predictDeterministicAddress(address(this), salt);
    splitInstance = PercentSplitETH(payable(clone));
    if (!clone.isContract()) {
      emit PercentSplitCreated(clone);
      Clones.cloneDeterministic(address(this), salt);
      splitInstance.initialize(shares);
    }
  }

  /**
   * @notice Returns the address for the proxy contract which would represent the given split terms.
   * @dev The contract may or may not already be deployed at the address returned.
   * Ensure that it is deployed before sending funds to this address.
   */
  function getPredictedSplitAddress(Share[] memory shares) external view returns (address) {
    bytes32 salt = keccak256(abi.encode(shares));
    return Clones.predictDeterministicAddress(address(this), salt);
  }

  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This will be called by `createSplit` after deploying the proxy so it should never be called directly.
   */
  function initialize(Share[] memory shares) external initializer {
    require(shares.length >= 2, "Split: Too few recipients");
    require(shares.length <= 5, "Split: Too many recipients");
    uint256 total;
    unchecked {
      for (uint256 i = 0; i < shares.length; i++) {
        total += shares[i].percentInBasisPoints;
        _shares.push(shares[i]);
        emit PercentSplitShare(shares[i].recipient, shares[i].percentInBasisPoints);
      }
    }
    require(total == BASIS_POINTS, "Split: Total amount must equal 100%");
  }

  /**
   * @notice Returns a tuple with the terms of this split.
   */
  function getShares() external view returns (Share[] memory) {
    return _shares;
  }

  /**
   * @notice Returns how many recipients are part of this split.
   */
  function getShareLength() external view returns (uint256) {
    return _shares.length;
  }

  /**
   * @notice Returns a recipient in this split.
   */
  function getShareRecipientByIndex(uint256 index) external view returns (address payable) {
    return _shares[index].recipient;
  }

  /**
   * @notice Returns a recipient's percent share in basis points.
   */
  function getPercentInBasisPointsByIndex(uint256 index) external view returns (uint256) {
    return _shares[index].percentInBasisPoints;
  }

  /**
   * @notice Forwards any ETH received to the recipients in this split.
   * @dev Each recipient increases the gas required to split
   * and contract recipients may significantly increase the gas required.
   */
  receive() external payable {
    _splitETH(msg.value);
  }

  /**
   * @notice Allows any ETH stored by the contract to be split among recipients.
   * @dev Normally ETH is forwarded as it comes in, but a balance in this contract
   * is possible if it was sent before the contract was created or if self destruct was used.
   */
  function splitETH() external {
    _splitETH(address(this).balance);
  }

  function _splitETH(uint256 value) private {
    if (value > 0) {
      uint256 totalSent;
      uint256 amountToSend;
      unchecked {
        for (uint256 i = _shares.length - 1; i > 0; i--) {
          Share memory share = _shares[i];
          amountToSend = (value * share.percentInBasisPoints) / BASIS_POINTS;
          totalSent += amountToSend;
          share.recipient.sendValue(amountToSend);
          emit ETHTransferred(share.recipient, amountToSend);
        }
        // Favor the 1st recipient if there are any rounding issues
        amountToSend = value - totalSent;
      }
      _shares[0].recipient.sendValue(amountToSend);
      emit ETHTransferred(_shares[0].recipient, amountToSend);
    }
  }

  /**
   * @notice Anyone can call this function to split all available tokens at the provided address between the recipients.
   * @dev This contract is built to split ETH payments. The ability to attempt to split ERC20 tokens is here
   * just in case tokens were also sent so that they don't get locked forever in the contract.
   */
  function splitERC20Tokens(IERC20 erc20Contract) external {
    require(_splitERC20Tokens(erc20Contract), "Split: ERC20 split failed");
  }

  function _splitERC20Tokens(IERC20 erc20Contract) private returns (bool) {
    try erc20Contract.balanceOf(address(this)) returns (uint256 balance) {
      if (balance == 0) {
        return false;
      }
      uint256 amountToSend;
      uint256 totalSent;
      unchecked {
        for (uint256 i = _shares.length - 1; i > 0; i--) {
          Share memory share = _shares[i];
          bool success;
          (success, amountToSend) = balance.tryMul(share.percentInBasisPoints);
          if (!success) {
            return false;
          }
          amountToSend /= BASIS_POINTS;
          totalSent += amountToSend;
          try erc20Contract.transfer(share.recipient, amountToSend) {
            emit ERC20Transferred(address(erc20Contract), share.recipient, amountToSend);
          } catch {
            return false;
          }
        }
        // Favor the 1st recipient if there are any rounding issues
        amountToSend = balance - totalSent;
      }
      try erc20Contract.transfer(_shares[0].recipient, amountToSend) {
        emit ERC20Transferred(address(erc20Contract), _shares[0].recipient, amountToSend);
      } catch {
        return false;
      }
      return true;
    } catch {
      return false;
    }
  }

  /**
   * @notice Allows the split recipients to make an arbitrary contract call.
   * @dev This is provided to allow recovering from unexpected scenarios,
   * such as receiving an NFT at this address.
   *
   * It will first attempt a fair split of ERC20 tokens before proceeding.
   *
   * This contract is built to split ETH payments. The ability to attempt to make other calls is here
   * just in case other assets were also sent so that they don't get locked forever in the contract.
   */
  function proxyCall(address payable target, bytes memory callData) external onlyRecipient {
    require(!callData.startsWith(type(IERC20Approve).interfaceId), "Split: ERC20 tokens must be split");
    _splitERC20Tokens(IERC20(target));
    target.functionCall(callData);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/ICollectionContractInitializer.sol";
import "./interfaces/ICollectionFactory.sol";
import "./interfaces/IGetRoyalties.sol";
import "./interfaces/IProxyCall.sol";
import "./interfaces/ITokenCreator.sol";
import "./interfaces/IGetFees.sol";

import "./libraries/AccountMigrationLibrary.sol";
import "./libraries/ProxyCall.sol";
import "./libraries/BytesLibrary.sol";
import "./interfaces/IRoyaltyInfo.sol";

/**
 * @title A collection of NFTs.
 * @notice All NFTs from this contract are minted by the same creator.
 * A 10% royalty to the creator is included which may be split with collaborators.
 */
contract CollectionContract is
  ICollectionContractInitializer,
  IGetRoyalties,
  IGetFees,
  IRoyaltyInfo,
  ITokenCreator,
  ERC721BurnableUpgradeable
{
  using AccountMigrationLibrary for address;
  using AddressUpgradeable for address;
  using BytesLibrary for bytes;
  using ProxyCall for IProxyCall;

  uint256 private constant ROYALTY_IN_BASIS_POINTS = 1000;
  uint256 private constant ROYALTY_RATIO = 10;

  /**
   * @notice The baseURI to use for the tokenURI, if undefined then `ipfs://` is used.
   */
  string private baseURI_;

  /**
   * @dev Stores hashes minted to prevent duplicates.
   */
  mapping(string => bool) private cidToMinted;

  /**
   * @notice The factory which was used to create this collection.
   * @dev This is used to read common config.
   */
  ICollectionFactory public immutable collectionFactory;

  /**
   * @notice The tokenId of the most recently created NFT.
   * @dev Minting starts at tokenId 1. Each mint will use this value + 1.
   */
  uint256 public latestTokenId;

  /**
   * @notice The max tokenId which can be minted, or 0 if there's no limit.
   * @dev This value may be set at any time, but once set it cannot be increased.
   */
  uint256 public maxTokenId;

  /**
   * @notice The owner/creator of this NFT collection.
   */
  address payable public owner;

  /**
   * @dev Stores an optional alternate address to receive creator revenue and royalty payments.
   * The target address may be a contract which could split or escrow payments.
   */
  mapping(uint256 => address payable) private tokenIdToCreatorPaymentAddress;

  /**
   * @dev Tracks how many tokens have been burned, used to calc the total supply efficiently.
   */
  uint256 private burnCounter;

  /**
   * @dev Stores a CID for each NFT.
   */
  mapping(uint256 => string) private _tokenCIDs;

  event BaseURIUpdated(string baseURI);
  event CreatorMigrated(address indexed originalAddress, address indexed newAddress);
  event MaxTokenIdUpdated(uint256 indexed maxTokenId);
  event Minted(address indexed creator, uint256 indexed tokenId, string indexed indexedTokenCID, string tokenCID);
  event NFTOwnerMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  event PaymentAddressMigrated(
    uint256 indexed tokenId,
    address indexed originalAddress,
    address indexed newAddress,
    address originalPaymentAddress,
    address newPaymentAddress
  );
  event SelfDestruct(address indexed owner);
  event TokenCreatorPaymentAddressSet(
    address indexed fromPaymentAddress,
    address indexed toPaymentAddress,
    uint256 indexed tokenId
  );

  modifier onlyOwner() {
    require(msg.sender == owner, "CollectionContract: Caller is not owner");
    _;
  }

  modifier onlyOperator() {
    require(collectionFactory.rolesContract().isOperator(msg.sender), "CollectionContract: Caller is not an operator");
    _;
  }

  /**
   * @dev The constructor for a proxy can only be used to assign immutable variables.
   */
  constructor(address _collectionFactory) {
    require(_collectionFactory.isContract(), "CollectionContract: collectionFactory is not a contract");
    collectionFactory = ICollectionFactory(_collectionFactory);
  }

  /**
   * @notice Called by the factory on creation.
   * @dev This may only be called once.
   */
  function initialize(
    address payable _creator,
    string memory _name,
    string memory _symbol
  ) external initializer {
    require(msg.sender == address(collectionFactory), "CollectionContract: Collection must be created via the factory");

    __ERC721_init_unchained(_name, _symbol);

    owner = _creator;
  }

  /**
   * @notice Allows the owner to mint an NFT defined by its metadata path.
   */
  function mint(string calldata tokenCID) external returns (uint256 tokenId) {
    tokenId = _mint(tokenCID);
  }

  /**
   * @notice Allows the owner to mint and sets approval for all for the provided operator.
   * @dev This can be used by creators the first time they mint an NFT to save having to issue a separate approval
   * transaction before starting an auction.
   */
  function mintAndApprove(string calldata tokenCID, address operator) external returns (uint256 tokenId) {
    tokenId = _mint(tokenCID);
    setApprovalForAll(operator, true);
  }

  /**
   * @notice Allows the owner to mint an NFT and have creator revenue/royalties sent to an alternate address.
   */
  function mintWithCreatorPaymentAddress(string calldata tokenCID, address payable tokenCreatorPaymentAddress)
    public
    returns (uint256 tokenId)
  {
    require(tokenCreatorPaymentAddress != address(0), "CollectionContract: tokenCreatorPaymentAddress is required");
    tokenId = _mint(tokenCID);
    _setTokenCreatorPaymentAddress(tokenId, tokenCreatorPaymentAddress);
  }

  /**
   * @notice Allows the owner to mint an NFT and have creator revenue/royalties sent to an alternate address.
   * Also sets approval for all for the provided operator.
   * @dev This can be used by creators the first time they mint an NFT to save having to issue a separate approval
   * transaction before starting an auction.
   */
  function mintWithCreatorPaymentAddressAndApprove(
    string calldata tokenCID,
    address payable tokenCreatorPaymentAddress,
    address operator
  ) external returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentAddress(tokenCID, tokenCreatorPaymentAddress);
    setApprovalForAll(operator, true);
  }

  /**
   * @notice Allows the owner to mint an NFT and have creator revenue/royalties sent to an alternate address
   * which is defined by a contract call, typically a proxy contract address representing the payment terms.
   * @param paymentAddressFactory The contract to call which will return the address to use for payments.
   * @param paymentAddressCallData The call details to sent to the factory provided.
   */
  function mintWithCreatorPaymentFactory(
    string calldata tokenCID,
    address paymentAddressFactory,
    bytes calldata paymentAddressCallData
  ) public returns (uint256 tokenId) {
    address payable tokenCreatorPaymentAddress = collectionFactory
      .proxyCallContract()
      .proxyCallAndReturnContractAddress(paymentAddressFactory, paymentAddressCallData);
    tokenId = mintWithCreatorPaymentAddress(tokenCID, tokenCreatorPaymentAddress);
  }

  /**
   * @notice Allows the owner to mint an NFT and have creator revenue/royalties sent to an alternate address
   * which is defined by a contract call, typically a proxy contract address representing the payment terms.
   * Also sets approval for all for the provided operator.
   * @param paymentAddressFactory The contract to call which will return the address to use for payments.
   * @param paymentAddressCallData The call details to sent to the factory provided.
   * @dev This can be used by creators the first time they mint an NFT to save having to issue a separate approval
   * transaction before starting an auction.
   */
  function mintWithCreatorPaymentFactoryAndApprove(
    string calldata tokenCID,
    address paymentAddressFactory,
    bytes calldata paymentAddressCallData,
    address operator
  ) external returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentFactory(tokenCID, paymentAddressFactory, paymentAddressCallData);
    setApprovalForAll(operator, true);
  }

  /**
   * @notice Allows the owner to set a max tokenID.
   * This provides a guarantee to collectors about the limit of this collection contract, if applicable.
   * @dev Once this value has been set, it may be decreased but can never be increased.
   */
  function updateMaxTokenId(uint256 _maxTokenId) external onlyOwner {
    require(_maxTokenId > 0, "CollectionContract: Max token ID may not be cleared");
    require(maxTokenId == 0 || _maxTokenId < maxTokenId, "CollectionContract: Max token ID may not increase");
    require(latestTokenId + 1 <= _maxTokenId, "CollectionContract: Max token ID must be greater than last mint");
    maxTokenId = _maxTokenId;

    emit MaxTokenIdUpdated(_maxTokenId);
  }

  /**
   * @notice Allows the owner to assign a baseURI to use for the tokenURI instead of the default `ipfs://`.
   */
  function updateBaseURI(string calldata baseURIOverride) external onlyOwner {
    baseURI_ = baseURIOverride;

    emit BaseURIUpdated(baseURIOverride);
  }

  /**
   * @notice Allows the creator to burn if they currently own the NFT.
   */
  function burn(uint256 tokenId) public override onlyOwner {
    super.burn(tokenId);
  }

  /**
   * @notice Allows the collection owner to destroy this contract only if
   * no NFTs have been minted yet.
   */
  function selfDestruct() external onlyOwner {
    require(totalSupply() == 0, "CollectionContract: Any NFTs minted must be burned first");
    emit SelfDestruct(msg.sender);
    selfdestruct(payable(msg.sender));
  }

  /**
   * @notice Allows an NFT owner or creator and Foundation to work together in order to update the creator
   * to a new account and/or transfer NFTs to that account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   * @dev This will gracefully skip any NFTs that have been burned or transferred.
   */
  function adminAccountMigration(
    uint256[] calldata ownedTokenIds,
    address originalAddress,
    address payable newAddress,
    bytes memory signature
  ) external onlyOperator {
    originalAddress.requireAuthorizedAccountMigration(newAddress, signature);

    for (uint256 i = 0; i < ownedTokenIds.length; i++) {
      uint256 tokenId = ownedTokenIds[i];
      // Check that the token exists and still is owned by the originalAddress
      // so that frontrunning a burn or transfer will not cause the entire tx to revert
      if (_exists(tokenId) && ownerOf(tokenId) == originalAddress) {
        _transfer(originalAddress, newAddress, tokenId);
        emit NFTOwnerMigrated(tokenId, originalAddress, newAddress);
      }
    }

    if (owner == originalAddress) {
      owner = newAddress;
      emit CreatorMigrated(originalAddress, newAddress);
    }
  }

  /**
   * @notice Allows a split recipient and Foundation to work together in order to update the payment address
   * to a new account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function adminAccountMigrationForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress,
    bytes memory signature
  ) external onlyOperator {
    originalAddress.requireAuthorizedAccountMigration(newAddress, signature);
    _adminAccountRecoveryForPaymentAddresses(
      paymentAddressTokenIds,
      paymentAddressFactory,
      paymentAddressCallData,
      addressLocationInCallData,
      originalAddress,
      newAddress
    );
  }

  function baseURI() external view returns (string memory) {
    return _baseURI();
  }

  /**
   * @notice Returns an array of recipient addresses to which royalties for secondary sales should be sent.
   * The expected royalty amount is communicated with `getFeeBps`.
   */
  function getFeeRecipients(uint256 id) external view returns (address payable[] memory recipients) {
    recipients = new address payable[](1);
    recipients[0] = getTokenCreatorPaymentAddress(id);
  }

  /**
   * @notice Returns an array of royalties to be sent for secondary sales in basis points.
   * The expected recipients is communicated with `getFeeRecipients`.
   */
  function getFeeBps(
    uint256 /* id */
  ) external pure returns (uint256[] memory feesInBasisPoints) {
    feesInBasisPoints = new uint256[](1);
    feesInBasisPoints[0] = ROYALTY_IN_BASIS_POINTS;
  }

  /**
   * @notice Checks if the creator has already minted a given NFT using this collection contract.
   */
  function getHasMintedCID(string calldata tokenCID) external view returns (bool) {
    return cidToMinted[tokenCID];
  }

  /**
   * @notice Returns an array of royalties to be sent for secondary sales.
   */
  function getRoyalties(uint256 tokenId)
    external
    view
    returns (address payable[] memory recipients, uint256[] memory feesInBasisPoints)
  {
    recipients = new address payable[](1);
    recipients[0] = getTokenCreatorPaymentAddress(tokenId);
    feesInBasisPoints = new uint256[](1);
    feesInBasisPoints[0] = ROYALTY_IN_BASIS_POINTS;
  }

  /**
   * @notice Returns the receiver and the amount to be sent for a secondary sale.
   */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    receiver = getTokenCreatorPaymentAddress(_tokenId);
    unchecked {
      royaltyAmount = _salePrice / ROYALTY_RATIO;
    }
  }

  /**
   * @notice Returns the creator for an NFT, which is always the collection owner.
   */
  function tokenCreator(
    uint256 /* tokenId */
  ) external view returns (address payable) {
    return owner;
  }

  /**
   * @notice Returns the desired payment address to be used for any transfers to the creator.
   * @dev The payment address may be assigned for each individual NFT, if not defined the collection owner is returned.
   */
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    public
    view
    returns (address payable tokenCreatorPaymentAddress)
  {
    tokenCreatorPaymentAddress = tokenIdToCreatorPaymentAddress[tokenId];
    if (tokenCreatorPaymentAddress == address(0)) {
      tokenCreatorPaymentAddress = owner;
    }
  }

  /**
   * @notice Count of NFTs tracked by this contract.
   * @dev From the ERC-721 enumerable standard.
   */
  function totalSupply() public view returns (uint256) {
    unchecked {
      return latestTokenId - burnCounter;
    }
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    if (
      interfaceId == type(IRoyaltyInfo).interfaceId ||
      interfaceId == type(ITokenCreator).interfaceId ||
      interfaceId == type(IGetRoyalties).interfaceId ||
      interfaceId == type(IGetFees).interfaceId
    ) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "CollectionContract: URI query for nonexistent token");

    return string(abi.encodePacked(_baseURI(), _tokenCIDs[tokenId]));
  }

  function _mint(string calldata tokenCID) private onlyOwner returns (uint256 tokenId) {
    require(bytes(tokenCID).length > 0, "CollectionContract: tokenCID is required");
    require(!cidToMinted[tokenCID], "CollectionContract: NFT was already minted");
    unchecked {
      tokenId = ++latestTokenId;
      require(maxTokenId == 0 || tokenId <= maxTokenId, "CollectionContract: Max token count has already been minted");
      cidToMinted[tokenCID] = true;
      _tokenCIDs[tokenId] = tokenCID;
      _mint(msg.sender, tokenId);
      emit Minted(msg.sender, tokenId, tokenCID, tokenCID);
    }
  }

  /**
   * @dev Allow setting a different address to send payments to for both primary sale revenue
   * and secondary sales royalties.
   */
  function _setTokenCreatorPaymentAddress(uint256 tokenId, address payable tokenCreatorPaymentAddress) internal {
    emit TokenCreatorPaymentAddressSet(tokenIdToCreatorPaymentAddress[tokenId], tokenCreatorPaymentAddress, tokenId);
    tokenIdToCreatorPaymentAddress[tokenId] = tokenCreatorPaymentAddress;
  }

  function _burn(uint256 tokenId) internal override {
    delete cidToMinted[_tokenCIDs[tokenId]];
    delete tokenIdToCreatorPaymentAddress[tokenId];
    delete _tokenCIDs[tokenId];
    unchecked {
      burnCounter++;
    }
    super._burn(tokenId);
  }

  /**
   * @dev Split into a second function to avoid stack too deep errors
   */
  function _adminAccountRecoveryForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress
  ) private {
    // Call the factory and get the originalPaymentAddress
    address payable originalPaymentAddress = collectionFactory.proxyCallContract().proxyCallAndReturnContractAddress(
      paymentAddressFactory,
      paymentAddressCallData
    );

    // Confirm the original address and swap with the new address
    paymentAddressCallData.replaceAtIf(addressLocationInCallData, originalAddress, newAddress);

    // Call the factory and get the newPaymentAddress
    address payable newPaymentAddress = collectionFactory.proxyCallContract().proxyCallAndReturnContractAddress(
      paymentAddressFactory,
      paymentAddressCallData
    );

    // For each token, confirm the expected payment address and then update to the new one
    unchecked {
      for (uint256 i = 0; i < paymentAddressTokenIds.length; i++) {
        uint256 tokenId = paymentAddressTokenIds[i];
        require(
          tokenIdToCreatorPaymentAddress[tokenId] == originalPaymentAddress,
          "CollectionContract: Payment address is not the expected value"
        );

        _setTokenCreatorPaymentAddress(tokenId, newPaymentAddress);
        emit PaymentAddressMigrated(tokenId, originalAddress, newAddress, originalPaymentAddress, newPaymentAddress);
      }
    }
  }

  function _baseURI() internal view override returns (string memory) {
    if (bytes(baseURI_).length > 0) {
      return baseURI_;
    }
    return "ipfs://";
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @dev Constant values shared across mixins.
 */
abstract contract Constants {
  uint256 internal constant BASIS_POINTS = 10000;

  uint256 internal constant MIN_PERCENT_INCREMENT_IN_BASIS_POINTS = 1000; // 10%

  uint256 internal constant READ_ONLY_GAS_LIMIT = 40000;

  /**
   * @dev Support up to 5 royalty recipients. A cap is required to ensure gas costs are not too high
   * when an auction is finalized.
   */
  uint256 internal constant MAX_CREATOR_INDEX = 4;
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

pragma solidity >=0.8.4;

import "./ENS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../root/Controllable.sol";

abstract contract NameResolver {
    function setName(bytes32 node, string memory name) public virtual;
}

bytes32 constant lookup = 0x3031323334353637383961626364656600000000000000000000000000000000;

bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

// namehash('addr.reverse')

contract ReverseRegistrar is Ownable, Controllable {
    ENS public ens;
    NameResolver public defaultResolver;

    event ReverseClaimed(address indexed addr, bytes32 indexed node);

    /**
     * @dev Constructor
     * @param ensAddr The address of the ENS registry.
     * @param resolverAddr The address of the default reverse resolver.
     */
    constructor(ENS ensAddr, NameResolver resolverAddr) {
        ens = ensAddr;
        defaultResolver = resolverAddr;

        // Assign ownership of the reverse record to our deployer
        ReverseRegistrar oldRegistrar = ReverseRegistrar(
            ens.owner(ADDR_REVERSE_NODE)
        );
        if (address(oldRegistrar) != address(0x0)) {
            oldRegistrar.claim(msg.sender);
        }
    }

    modifier authorised(address addr) {
        require(
            addr == msg.sender ||
                controllers[msg.sender] ||
                ens.isApprovedForAll(addr, msg.sender) ||
                ownsContract(addr),
            "Caller is not a controller or authorised by address or the address itself"
        );
        _;
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claim(address owner) public returns (bytes32) {
        return _claimWithResolver(msg.sender, owner, address(0x0));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param addr The reverse record to set
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claimForAddr(address addr, address owner)
        public
        authorised(addr)
        returns (bytes32)
    {
        return _claimWithResolver(addr, owner, address(0x0));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolver(address owner, address resolver)
        public
        returns (bytes32)
    {
        return _claimWithResolver(msg.sender, owner, resolver);
    }

    /**
     * @dev Transfers ownership of the reverse ENS record specified with the
     *      address provided
     * @param addr The reverse record to set
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolverForAddr(
        address addr,
        address owner,
        address resolver
    ) public authorised(addr) returns (bytes32) {
        return _claimWithResolver(addr, owner, resolver);
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account. First updates the resolver to the default reverse
     * resolver if necessary.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string memory name) public returns (bytes32) {
        bytes32 node = _claimWithResolver(
            msg.sender,
            address(this),
            address(defaultResolver)
        );
        defaultResolver.setName(node, name);
        return node;
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the account provided. First updates the resolver to the default reverse
     * resolver if necessary.
     * Only callable by controllers and authorised users
     * @param addr The reverse record to set
     * @param owner The owner of the reverse node
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setNameForAddr(
        address addr,
        address owner,
        string memory name
    ) public authorised(addr) returns (bytes32) {
        bytes32 node = _claimWithResolver(
            addr,
            address(this),
            address(defaultResolver)
        );
        defaultResolver.setName(node, name);
        ens.setSubnodeOwner(ADDR_REVERSE_NODE, sha3HexAddress(addr), owner);
        return node;
    }

    /**
     * @dev Returns the node hash for a given account's reverse records.
     * @param addr The address to hash
     * @return The ENS node hash.
     */
    function node(address addr) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr))
            );
    }

    /**
     * @dev An optimised function to compute the sha3 of the lower-case
     *      hexadecimal representation of an Ethereum address.
     * @param addr The address to hash
     * @return ret The SHA3 hash of the lower-case hexadecimal encoding of the
     *         input address.
     */
    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        assembly {
            for {
                let i := 40
            } gt(i, 0) {

            } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }

    /* Internal functions */

    function _claimWithResolver(
        address addr,
        address owner,
        address resolver
    ) internal returns (bytes32) {
        bytes32 label = sha3HexAddress(addr);
        bytes32 node = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, label));
        address currentResolver = ens.resolver(node);
        bool shouldUpdateResolver = (resolver != address(0x0) &&
            resolver != currentResolver);
        address newResolver = shouldUpdateResolver ? resolver : currentResolver;

        ens.setSubnodeRecord(ADDR_REVERSE_NODE, label, owner, newResolver, 0);

        emit ReverseClaimed(addr, node);

        return node;
    }

    function ownsContract(address addr) internal view returns (bool) {
        try Ownable(addr).owner() returns (address owner) {
            return owner == msg.sender;
        } catch {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../registry/ENS.sol";
import "./profiles/ABIResolver.sol";
import "./profiles/AddrResolver.sol";
import "./profiles/ContentHashResolver.sol";
import "./profiles/DNSResolver.sol";
import "./profiles/InterfaceResolver.sol";
import "./profiles/NameResolver.sol";
import "./profiles/PubkeyResolver.sol";
import "./profiles/TextResolver.sol";
import "./Multicallable.sol";

interface INameWrapper {
    function ownerOf(uint256 id) external view returns (address);
}

/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract PublicResolver is Multicallable, ABIResolver, AddrResolver, ContentHashResolver, DNSResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver {
    ENS ens;
    INameWrapper nameWrapper;

    /**
     * A mapping of operators. An address that is authorised for an address
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     * (owner, operator) => approved
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(ENS _ens, INameWrapper wrapperAddress){
        ens = _ens;
        nameWrapper = wrapperAddress;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external{
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isAuthorised(bytes32 node) internal override view returns(bool) {
        address owner = ens.owner(node);
        if(owner == address(nameWrapper) ){
            owner = nameWrapper.ownerOf(uint256(node));
        }
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view returns (bool){
        return _operatorApprovals[account][operator];
    }

    function supportsInterface(bytes4 interfaceID) public override(Multicallable, ABIResolver, AddrResolver, ContentHashResolver, DNSResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver) pure returns(bool) {
        return interfaceID == type(IMulticallable).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

error FoundationTreasuryNode_Address_Is_Not_A_Contract();

/**
 * @notice A mixin that stores a reference to the Foundation treasury contract.
 */
abstract contract FoundationTreasuryNode is Initializable {
  using AddressUpgradeable for address payable;

  address payable private ____gap_was_treasury;

  address payable private immutable TREASURY;

  constructor(address payable _treasury) {
    if (!_treasury.isContract()) {
      revert FoundationTreasuryNode_Address_Is_Not_A_Contract();
    }
    TREASURY = _treasury;
  }

  /**
   * @notice Returns the address of the Foundation treasury.
   */
  function getFoundationTreasury() public view returns (address payable) {
    return TREASURY;
  }

  // `______gap` is added to each mixin to allow adding new data slots or additional mixins in an upgrade-safe way.
  uint256[2000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../../interfaces/IAdminRole.sol";

import "../FoundationTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the admin role defined by the Foundation treasury.
 */
abstract contract FoundationAdminRole is FoundationTreasuryNode {
  // This file uses 0 data slots (other than what's included via FoundationTreasuryNode)

  modifier onlyFoundationAdmin() {
    require(isAdmin(msg.sender), "FoundationAdminRole: caller does not have the Admin role");
    _;
  }

  /**
   * @notice Returns true if the user is a Foundation admin.
   * @dev This API may be consumed by 3rd party contracts.
   */
  function isAdmin(address user) public view returns (bool) {
    return IAdminRole(getFoundationTreasury()).isAdmin(user);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../../interfaces/IOperatorRole.sol";

import "../FoundationTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the operator role defined by the Foundation treasury.
 */
abstract contract FoundationOperatorRole is FoundationTreasuryNode {
  // This file uses 0 data slots (other than what's included via FoundationTreasuryNode)

  function _isFoundationOperator() internal view returns (bool) {
    return IOperatorRole(getFoundationTreasury()).isOperator(msg.sender);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../interfaces/IFethMarket.sol";
import "./Constants.sol";

error NFTMarketCore_FETH_Address_Is_Not_A_Contract();
error NFTMarketCore_Only_FETH_Can_Transfer_ETH(address sender);

/**
 * @notice A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTMarketCore is Constants {
  using AddressUpgradeable for address;

  /// @notice The FETH ERC-20 token for managing escrow and lockup.
  IFethMarket public immutable feth;

  constructor(address _feth) {
    if (!_feth.isContract()) {
      revert NFTMarketCore_FETH_Address_Is_Not_A_Contract();
    }
    feth = IFethMarket(_feth);
  }

  /**
   * @notice Only used by FETH. Any direct transfer from users will revert.
   */
  receive() external payable {
    if (msg.sender != address(feth)) {
      revert NFTMarketCore_Only_FETH_Can_Transfer_ETH(msg.sender);
    }
  }

  /**
   * @dev If the NFT did not have an escrowed seller to return, this falls back to return the current owner.
   * This allows functions to calculate the correct fees before the NFT has been listed in auction.
   */
  function _getSellerFor(address nftContract, uint256 tokenId) internal view virtual returns (address payable) {
    return payable(IERC721(nftContract).ownerOf(tokenId));
  }

  /**
   * @dev Returns true if the NFT is available in auction and no bids have been placed yet.
   */
  function _hasAuctionReservePrice(
    address, /*nftContract*/
    uint256 /*tokenId*/
  ) internal view virtual returns (bool);

  /**
   * @dev Returns true if the NFT has a valid buy now price set.
   * Reverts if there is a buy now price but the seller does not match.
   */
  function _hasBuyNowPrice(
    address nftContract,
    uint256 tokenId,
    address seller
  ) internal view virtual returns (bool);

  /**
   * @dev Implementors of this interface should update internal state to reflect an auction has been kicked off.
   */
  function _auctionStarted(
    address, /*nftContract*/
    uint256 /*tokenId*/ // solhint-disable-next-line no-empty-blocks
  ) internal virtual {
    // No-op
  }

  /**
   * @dev Implementors of this interface should update internal state to reflect a buy now offer has been met.
   */
  function _buyNowPriceMet(
    address, /*nftContract*/
    uint256, /*tokenId*/
    address /*buyer*/ // solhint-disable-next-line no-empty-blocks
  ) internal virtual {
    // No-op
  }

  /**
   * @dev Implementors of this interface should update internal state to reflect an offer in escrow has been accepted.
   */
  function _offerAccepted(
    address, /*nftContract*/
    uint256 /*tokenId*/ // solhint-disable-next-line no-empty-blocks
  ) internal virtual {
    // No-op
  }

  /**
   * @dev Determines the minimum amount when increasing an existing offer or bid.
   */
  function _getMinIncrement(uint256 currentAmount) internal pure returns (uint256) {
    uint256 minIncrement = currentAmount * MIN_PERCENT_INCREMENT_IN_BASIS_POINTS;

    // Since minIncrement reduces from the currentAmount, this block cannot overflow.
    unchecked {
      minIncrement /= BASIS_POINTS;
      if (minIncrement == 0) {
        // The next amount must be at least 1 wei greater than the current.
        return currentAmount + 1;
      }
    }

    return minIncrement + currentAmount;
  }

  function _autoBuy(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) internal virtual returns (bool);

  /**
   * @dev Checks if an escrowed NFT is currently in active auction.
   * This returns false if the auction has ended, even if it has not yet been settled.
   */
  function _isInActiveAuction(address nftContract, uint256 tokenId) internal view virtual returns (bool);

  /**
   * @dev Settles an auction if there was one which has already ended.
   * @return true if the auction was settled.
   */
  function _autoSettleAuctionAndTransfer(
    address nftContract,
    uint256 tokenId,
    address seller,
    address buyer
  ) internal virtual returns (bool);

  function _isAuctionEscrowSeller(
    address nftContract,
    uint256 tokenId,
    address seller,
    bool addReentrancyGuard
  ) internal virtual returns (bool);

  // 50 slots were consumed by adding ReentrancyGuard
  uint256[950] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

error SendValueWithFallbackWithdraw_No_Funds_Available();

/**
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuardUpgradeable {
  using AddressUpgradeable for address payable;

  mapping(address => uint256) private pendingWithdrawals;

  event WithdrawPending(address indexed user, uint256 amount);
  event Withdrawal(address indexed user, uint256 amount);

  /**
   * @notice Returns how much funds are available for manual withdraw due to failed transfers.
   */
  function getPendingWithdrawal(address user) external view returns (uint256) {
    return pendingWithdrawals[user];
  }

  /**
   * @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
   */
  function withdraw() external {
    withdrawFor(payable(msg.sender));
  }

  /**
   * @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
   */
  function withdrawFor(address payable user) public nonReentrant {
    uint256 amount = pendingWithdrawals[user];
    if (amount == 0) {
      revert SendValueWithFallbackWithdraw_No_Funds_Available();
    }
    pendingWithdrawals[user] = 0;
    user.sendValue(amount);
    emit Withdrawal(user, amount);
  }

  /**
   * @dev Attempt to send a user ETH with a reasonably low gas limit of 20k,
   * which is enough to send to contracts as well.
   */
  function _sendValueWithFallbackWithdrawWithLowGasLimit(address payable user, uint256 amount) internal {
    _sendValueWithFallbackWithdraw(user, amount, 20000);
  }

  /**
   * @dev Attempt to send a user or contract ETH with a moderate gas limit of 90k,
   * which is enough for a 5-way split.
   */
  function _sendValueWithFallbackWithdrawWithMediumGasLimit(address payable user, uint256 amount) internal {
    _sendValueWithFallbackWithdraw(user, amount, 210000);
  }

  /**
   * @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdrawal.
   */
  function _sendValueWithFallbackWithdraw(
    address payable user,
    uint256 amount,
    uint256 gasLimit
  ) private {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
    if (!success) {
      // Record failed sends for a withdrawal later
      // Transfers could fail if sent to a multisig with non-trivial receiver logic
      unchecked {
        pendingWithdrawals[user] += amount;
      }
      emit WithdrawPending(user, amount);
    }
  }

  uint256[499] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../interfaces/IFNDNFT721.sol";
import "../interfaces/ITokenCreator.sol";
import "../interfaces/IGetRoyalties.sol";
import "../interfaces/IGetFees.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IRoyaltyInfo.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyRegistry.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./OZ/ERC165Checker.sol";

import "./Constants.sol";

error NFTMarketCreators_Address_Does_Not_Support_IRoyaltyRegistry();

/**
 * @notice A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract NFTMarketCreators is
  Constants,
  ReentrancyGuardUpgradeable // Adding this unused mixin to help with linearization
{
  using ERC165Checker for address;

  IRoyaltyRegistry private immutable royaltyRegistry;

  constructor(address _royaltyRegistry) {
    if (!_royaltyRegistry.supportsInterface(type(IRoyaltyRegistry).interfaceId)) {
      revert NFTMarketCreators_Address_Does_Not_Support_IRoyaltyRegistry();
    }
    royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
  }

  /**
   * @dev Returns the destination address for any payments to the creator,
   * or address(0) if the destination is unknown.
   * It also checks if the current seller is the creator for isPrimary checks.
   */
  // solhint-disable-next-line code-complexity
  function _getCreatorPaymentInfo(
    address nftContract,
    uint256 tokenId,
    address seller
  )
    internal
    view
    returns (
      address payable[] memory recipients,
      uint256[] memory splitPerRecipientInBasisPoints,
      bool isCreator
    )
  {
    // All NFTs implement 165 so we skip that check, individual interfaces should return false if 165 is not implemented

    // 1st priority: ERC-2981
    if (nftContract.supportsERC165Interface(type(IRoyaltyInfo).interfaceId)) {
      try IRoyaltyInfo(nftContract).royaltyInfo{ gas: READ_ONLY_GAS_LIMIT }(tokenId, BASIS_POINTS) returns (
        address receiver,
        uint256 /* royaltyAmount */
      ) {
        if (receiver != address(0)) {
          recipients = new address payable[](1);
          recipients[0] = payable(receiver);
          // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
          if (receiver == seller) {
            return (recipients, splitPerRecipientInBasisPoints, true);
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 2nd priority: getRoyalties
    if (recipients.length == 0 && nftContract.supportsERC165Interface(type(IGetRoyalties).interfaceId)) {
      try IGetRoyalties(nftContract).getRoyalties{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable[] memory _recipients,
        uint256[] memory recipientBasisPoints
      ) {
        if (_recipients.length > 0 && _recipients.length == recipientBasisPoints.length) {
          bool hasRecipient;
          unchecked {
            for (uint256 i = 0; i < _recipients.length; i++) {
              if (_recipients[i] != address(0)) {
                hasRecipient = true;
                if (_recipients[i] == seller) {
                  return (_recipients, recipientBasisPoints, true);
                }
              }
            }
          }
          if (hasRecipient) {
            recipients = _recipients;
            splitPerRecipientInBasisPoints = recipientBasisPoints;
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    /* Overrides must support ERC-165 when registered, except for overrides defined by the registry owner.
       If that results in an override w/o 165 we may need to upgrade the market to support or ignore that override. */
    // The registry requires overrides are not 0 and contracts when set.
    // If no override is set, the nftContract address is returned.
    if (recipients.length == 0) {
      try royaltyRegistry.getRoyaltyLookupAddress{ gas: READ_ONLY_GAS_LIMIT }(nftContract) returns (
        address overrideContract
      ) {
        if (overrideContract != nftContract) {
          nftContract = overrideContract;

          // The functions above are repeated here if an override is set.

          // 3rd priority: ERC-2981 override
          if (nftContract.supportsERC165Interface(type(IRoyaltyInfo).interfaceId)) {
            try IRoyaltyInfo(nftContract).royaltyInfo{ gas: READ_ONLY_GAS_LIMIT }(tokenId, BASIS_POINTS) returns (
              address receiver,
              uint256 /* royaltyAmount */
            ) {
              if (receiver != address(0)) {
                recipients = new address payable[](1);
                recipients[0] = payable(receiver);
                // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
                if (receiver == seller) {
                  return (recipients, splitPerRecipientInBasisPoints, true);
                }
              }
            } catch // solhint-disable-next-line no-empty-blocks
            {
              // Fall through
            }
          }

          // 4th priority: getRoyalties override
          if (recipients.length == 0 && nftContract.supportsERC165Interface(type(IGetRoyalties).interfaceId)) {
            try IGetRoyalties(nftContract).getRoyalties{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
              address payable[] memory _recipients,
              uint256[] memory recipientBasisPoints
            ) {
              if (_recipients.length > 0 && _recipients.length == recipientBasisPoints.length) {
                bool hasRecipient;
                for (uint256 i = 0; i < _recipients.length; i++) {
                  if (_recipients[i] != address(0)) {
                    hasRecipient = true;
                    if (_recipients[i] == seller) {
                      return (_recipients, recipientBasisPoints, true);
                    }
                  }
                }
                if (hasRecipient) {
                  recipients = _recipients;
                  splitPerRecipientInBasisPoints = recipientBasisPoints;
                }
              }
            } catch // solhint-disable-next-line no-empty-blocks
            {
              // Fall through
            }
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Ignore out of gas errors and continue using the nftContract address
      }
    }

    // 5th priority: getFee* from contract or override
    if (recipients.length == 0 && nftContract.supportsERC165Interface(type(IGetFees).interfaceId)) {
      try IGetFees(nftContract).getFeeRecipients{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable[] memory _recipients
      ) {
        if (_recipients.length > 0) {
          try IGetFees(nftContract).getFeeBps{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
            uint256[] memory recipientBasisPoints
          ) {
            if (_recipients.length == recipientBasisPoints.length) {
              bool hasRecipient;
              unchecked {
                for (uint256 i = 0; i < _recipients.length; i++) {
                  if (_recipients[i] != address(0)) {
                    hasRecipient = true;
                    if (_recipients[i] == seller) {
                      return (_recipients, recipientBasisPoints, true);
                    }
                  }
                }
              }
              if (hasRecipient) {
                recipients = _recipients;
                splitPerRecipientInBasisPoints = recipientBasisPoints;
              }
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 6th priority: tokenCreator w/ or w/o requiring 165 from contract or override
    try IFNDNFT721(nftContract).tokenCreator{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (address payable _creator) {
      if (_creator != address(0)) {
        if (recipients.length == 0) {
          // Only pay the tokenCreator if there wasn't another royalty defined
          recipients = new address payable[](1);
          recipients[0] = _creator;
          // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
        }
        return (recipients, splitPerRecipientInBasisPoints, _creator == seller);
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // 7th priority: owner from contract or override
    try IOwnable(nftContract).owner{ gas: READ_ONLY_GAS_LIMIT }() returns (address owner) {
      if (recipients.length == 0) {
        // Only pay the owner if there wasn't another royalty defined
        recipients = new address payable[](1);
        recipients[0] = payable(owner);
        // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
      }
      return (recipients, splitPerRecipientInBasisPoints, owner == seller);
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // If no valid payment address or creator is found, return 0 recipients
  }

  /**
   * @notice Returns the address of the registry allowing for royalty configuration overrides.
   */
  function getRoyaltyRegistry() public view returns (address) {
    return address(royaltyRegistry);
  }

  // 500 slots were added via the new SendValueWithFallbackWithdraw mixin
  uint256[500] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./FoundationTreasuryNode.sol";
import "./Constants.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketCreators.sol";
import "./SendValueWithFallbackWithdraw.sol";

/**
 * @notice A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is
  Constants,
  Initializable,
  FoundationTreasuryNode,
  NFTMarketCore,
  NFTMarketCreators,
  SendValueWithFallbackWithdraw
{
  uint256 private ____gap_was_primaryFoundationFeeBasisPoints;
  uint256 private ____gap_was_secondaryFoundationFeeBasisPoints;
  uint256 private ____gap_was_secondaryCreatorFeeBasisPoints;
  mapping(address => mapping(uint256 => bool)) private ____gap_was_nftContractToTokenIdToFirstSaleCompleted;

  uint256 private constant FOUNDATION_FEE_BASIS_POINTS = 500; // 5%
  uint256 private constant CREATOR_ROYALTY_BASIS_POINTS = 1000; // 10%

  /**
   * @notice Returns the current fee configuration in basis points.
   */
  function getFeeConfig()
    external
    pure
    returns (
      uint256 primaryFoundationFeeBasisPoints,
      uint256 secondaryFoundationFeeBasisPoints,
      uint256 secondaryCreatorFeeBasisPoints
    )
  {
    return (FOUNDATION_FEE_BASIS_POINTS, FOUNDATION_FEE_BASIS_POINTS, CREATOR_ROYALTY_BASIS_POINTS);
  }

  /**
   * @notice Returns how funds will be distributed for a sale at the given price point.
   * @dev This is required for backwards compatibility with subgraph.
   */
  function getFees(
    address nftContract,
    uint256 tokenId,
    uint256 price
  )
    external
    view
    returns (
      uint256 foundationFee,
      uint256 creatorRev,
      uint256 ownerRev
    )
  {
    address payable seller = _getSellerFor(nftContract, tokenId);
    (foundationFee, , , creatorRev, , ownerRev) = _getFees(nftContract, tokenId, seller, price);
  }

  /**
   * @notice Returns the address which will receive fees calculated from `getFees`.
   * @dev This is required for backwards compatibility with subgraph.
   */
  function getFeeRecipients(address nftContract, uint256 tokenId)
    public
    view
    returns (
      address payable[] memory creatorRecipients,
      uint256[] memory creatorShares,
      address payable owner
    )
  {
    address payable seller = _getSellerFor(nftContract, tokenId);
    (, creatorRecipients, creatorShares, , owner, ) = _getFees(nftContract, tokenId, seller, BASIS_POINTS);
  }

  /**
   * @dev Calculates how funds should be distributed for the given sale details.
   */
  function _getFees(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price
  )
    private
    view
    returns (
      uint256 foundationFee,
      address payable[] memory creatorRecipients,
      uint256[] memory creatorShares,
      uint256 creatorRev,
      address payable ownerRevTo,
      uint256 ownerRev
    )
  {
    bool isCreator;
    (creatorRecipients, creatorShares, isCreator) = _getCreatorPaymentInfo(nftContract, tokenId, seller);

    // Calculate the Foundation fee
    foundationFee = (price * FOUNDATION_FEE_BASIS_POINTS) / BASIS_POINTS;

    if (creatorRecipients.length > 0) {
      if (isCreator) {
        // When sold by the creator, all revenue is split if applicable.
        creatorRev = price - foundationFee;
      } else {
        // Rounding favors the owner first, then creator, and foundation last.
        creatorRev = (price * CREATOR_ROYALTY_BASIS_POINTS) / BASIS_POINTS;
        ownerRevTo = seller;
        ownerRev = price - foundationFee - creatorRev;
      }
    } else {
      // No royalty recipients found.
      ownerRevTo = seller;
      ownerRev = price - foundationFee;
    }
  }

  /**
   * @dev Distributes funds to foundation, creator, and NFT owner after a sale.
   * This call will respect the creator's payment address if defined.
   */
  // solhint-disable-next-line code-complexity
  function _distributeFunds(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price
  )
    internal
    returns (
      uint256 foundationFee,
      uint256 creatorFee,
      uint256 ownerRev
    )
  {
    address payable[] memory creatorRecipients;
    uint256[] memory creatorShares;

    address payable ownerRevTo;
    (foundationFee, creatorRecipients, creatorShares, creatorFee, ownerRevTo, ownerRev) = _getFees(
      nftContract,
      tokenId,
      seller,
      price
    );

    _sendValueWithFallbackWithdrawWithLowGasLimit(getFoundationTreasury(), foundationFee);

    if (creatorFee > 0) {
      if (creatorRecipients.length > 1) {
        uint256 maxCreatorIndex = creatorRecipients.length - 1;
        if (maxCreatorIndex > MAX_CREATOR_INDEX) {
          maxCreatorIndex = MAX_CREATOR_INDEX;
        }

        // Determine the total shares defined so it can be leveraged to distribute below
        uint256 totalShares;
        unchecked {
          for (uint256 i = 0; i <= maxCreatorIndex; i++) {
            if (creatorShares[i] > BASIS_POINTS) {
              // If the numbers are >100% we ignore the fee recipients and pay just the first instead
              maxCreatorIndex = 0;
              break;
            }
            totalShares += creatorShares[i];
          }
        }
        if (totalShares == 0) {
          maxCreatorIndex = 0;
        }

        // Send payouts to each additional recipient if more than 1 was defined
        uint256 totalDistributed;
        for (uint256 i = 1; i <= maxCreatorIndex; i++) {
          uint256 share = (creatorFee * creatorShares[i]) / totalShares;
          totalDistributed += share;
          _sendValueWithFallbackWithdrawWithMediumGasLimit(creatorRecipients[i], share);
        }

        // Send the remainder to the 1st creator, rounding in their favor
        _sendValueWithFallbackWithdrawWithMediumGasLimit(creatorRecipients[0], creatorFee - totalDistributed);
      } else {
        _sendValueWithFallbackWithdrawWithMediumGasLimit(creatorRecipients[0], creatorFee);
      }
    }
    _sendValueWithFallbackWithdrawWithMediumGasLimit(ownerRevTo, ownerRev);
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarketAuction {
  /**
   * @dev A global id for auctions of any type.
   */
  uint256 private nextAuctionId;

  function _initializeNFTMarketAuction() internal {
    nextAuctionId = 1;
  }

  function _getNextAndIncrementAuctionId() internal returns (uint256) {
    unchecked {
      return nextAuctionId++;
    }
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketFees.sol";
import "./SendValueWithFallbackWithdraw.sol";
import "./NFTMarketAuction.sol";
import "./roles/FoundationAdminRole.sol";
import "./AccountMigration.sol";

/**
 * @notice Custom Errors defined for NFTMarketReserveAuction.
 */
error NFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
error NFTMarketReserveAuction_Exceeds_Max_Duration(uint256 maxDuration);
error NFTMarketReserveAuction_Less_Than_Extension_Duration(uint256 extensionDuration);
error NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
error NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(address owner);
error NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
error NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(uint256 reservePrice);
error NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
error NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(uint256 minAmount);
error NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
error NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Admin_Cancel_Without_Reason();
error NFTMarketReserveAuction_Cannot_Cancel_Nonexistent_Auction();
error NFTMarketReserveAuction_Cannot_Migrate_Non_Matching_Seller(address seller);
error NFTMarketReserveAuction_Too_Much_Value_Provided();
error NFTMarketReserveAuction_Not_Matching_Seller(address seller);

/**
 * @notice Manages a reserve price auction for NFTs.
 */
abstract contract NFTMarketReserveAuction is
  Constants,
  FoundationAdminRole,
  AccountMigration,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction
{
  struct ReserveAuction {
    address nftContract;
    uint256 tokenId;
    address payable seller;
    uint256 duration;
    uint256 extensionDuration;
    uint256 endTime;
    address payable bidder;
    uint256 amount;
  }

  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToAuctionId;
  mapping(uint256 => ReserveAuction) private auctionIdToAuction;

  // These variables were used in an older version of the contract, left here as a gap to ensure upgrade compatibility
  uint256 private ______gap_was_minPercentIncrementInBasisPoints;
  uint256 private ______gap_was_maxBidIncrementRequirement;
  uint256 private ______gap_was_duration;
  uint256 private ______gap_was_extensionDuration;
  uint256 private ______gap_was_goLiveDate;

  // Cap the max duration so that overflows will not occur
  uint256 private constant MAX_MAX_DURATION = 1000 days;

  uint256 private constant EXTENSION_DURATION = 15 minutes;

  uint256 private immutable DURATION;

  event ReserveAuctionCreated(
    address indexed seller,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 duration,
    uint256 extensionDuration,
    uint256 reservePrice,
    uint256 auctionId
  );
  event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);
  event ReserveAuctionCanceled(uint256 indexed auctionId);
  event ReserveAuctionInvalidated(uint256 indexed auctionId);
  event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  event ReserveAuctionFinalized(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev
  );
  event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
  event ReserveAuctionSellerMigrated(
    uint256 indexed auctionId,
    address indexed originalSellerAddress,
    address indexed newSellerAddress
  );

  modifier onlyValidAuctionConfig(uint256 reservePrice) {
    if (reservePrice == 0) {
      revert NFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
    }
    _;
  }

  constructor(uint256 duration) {
    if (duration > MAX_MAX_DURATION) {
      revert NFTMarketReserveAuction_Exceeds_Max_Duration(MAX_MAX_DURATION);
    }
    if (duration < EXTENSION_DURATION) {
      revert NFTMarketReserveAuction_Less_Than_Extension_Duration(EXTENSION_DURATION);
    }
    DURATION = duration;
  }

  /**
   * @notice Returns auction details for a given auctionId.
   */
  function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory) {
    return auctionIdToAuction[auctionId];
  }

  /**
   * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
   * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
   */
  function getReserveAuctionIdFor(address nftContract, uint256 tokenId) external view returns (uint256) {
    return nftContractToTokenIdToAuctionId[nftContract][tokenId];
  }

  /**
   * @dev Returns the seller that put a given NFT into escrow,
   * or bubbles the call up to check the current owner if the NFT is not currently in escrow.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (address payable seller)
  {
    seller = auctionIdToAuction[nftContractToTokenIdToAuctionId[nftContract][tokenId]].seller;
    if (seller == address(0)) {
      return super._getSellerFor(nftContract, tokenId);
    }
    return seller;
  }

  /**
   * @notice Returns the current configuration for reserve auctions.
   */
  function getReserveAuctionConfig()
    external
    view
    returns (uint256 minPercentIncrementInBasisPoints, uint256 duration)
  {
    minPercentIncrementInBasisPoints = MIN_PERCENT_INCREMENT_IN_BASIS_POINTS;
    duration = DURATION;
  }

  /**
   * @notice Creates an auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   */
  function createReserveAuction(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice
  ) external nonReentrant onlyValidAuctionConfig(reservePrice) {
    // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed
    uint256 auctionId = _getNextAndIncrementAuctionId();

    // Check if already escrowed
    if (
      !_hasBuyNowPrice(nftContract, tokenId, msg.sender) &&
      !_isAuctionEscrowSeller(nftContract, tokenId, msg.sender, false)
    ) {
      IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }

    nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
    auctionIdToAuction[auctionId] = ReserveAuction(
      nftContract,
      tokenId,
      payable(msg.sender),
      DURATION,
      EXTENSION_DURATION,
      0, // endTime is only known once the reserve price is met
      payable(0), // bidder is only known once a bid has been placed
      reservePrice
    );

    emit ReserveAuctionCreated(msg.sender, nftContract, tokenId, DURATION, EXTENSION_DURATION, reservePrice, auctionId);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, the configuration
   * such as the reservePrice may be changed by the seller.
   */
  function updateReserveAuction(uint256 auctionId, uint256 reservePrice) external onlyValidAuctionConfig(reservePrice) {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    }
    if (auction.endTime != 0) {
      revert NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    }

    auction.amount = reservePrice;

    emit ReserveAuctionUpdated(auctionId, reservePrice);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
   * The NFT is returned to the seller from escrow.
   */
  function cancelReserveAuction(uint256 auctionId) external nonReentrant {
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    }
    if (auction.endTime != 0) {
      revert NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    }

    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    if (!_hasBuyNowPrice(auction.nftContract, auction.tokenId, auction.seller)) {
      IERC721(auction.nftContract).transferFrom(address(this), msg.sender, auction.tokenId);
    }
    emit ReserveAuctionCanceled(auctionId);
  }

  /**
   * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   */
  function placeBid(uint256 auctionId) external payable {
    placeBidOf(auctionId, msg.value);
  }

  /**
   * @notice A bidder may place a bid which is at least the amount defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   * @dev amount - msg.value is withdrawn from the bidder's FETH balance.
   */
  /* solhint-disable-next-line code-complexity */
  function placeBidOf(uint256 auctionId, uint256 amount) public payable nonReentrant {
    if (amount > msg.value) {
      // The if above ensures delta will not underflow
      unchecked {
        uint256 delta = amount - msg.value;
        feth.marketWithdrawFrom(msg.sender, delta);
      }
    } else if (amount < msg.value) {
      revert NFTMarketReserveAuction_Too_Much_Value_Provided();
    }

    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.amount == 0) {
      revert NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
    }

    if (auction.endTime == 0) {
      // If this is the first bid, ensure it's >= the reserve price
      if (auction.amount > amount) {
        revert NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(auction.amount);
      }
      // Notify implementors of _auctionStarted on auction kick-off.
      _auctionStarted(auction.nftContract, auction.tokenId);
    } else {
      // If this bid outbids another, confirm that the bid is at least x% greater than the last
      if (auction.endTime < block.timestamp) {
        revert NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(auction.endTime);
      }
      if (auction.bidder == msg.sender) {
        revert NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
      }
      if (amount < _getMinIncrement(auction.amount)) {
        revert NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(_getMinIncrement(auction.amount));
      }
    }

    if (auction.endTime == 0) {
      auction.amount = amount;
      auction.bidder = payable(msg.sender);
      // On the first bid, the endTime is now + duration
      unchecked {
        auction.endTime = block.timestamp + auction.duration;
      }
    } else {
      // Cache and update bidder state before a possible reentrancy (via the value transfer)
      uint256 originalAmount = auction.amount;
      address payable originalBidder = auction.bidder;
      auction.amount = amount;
      auction.bidder = payable(msg.sender);

      // When a bid outbids another, check to see if a time extension should apply.
      unchecked {
        if (auction.endTime - block.timestamp < auction.extensionDuration) {
          auction.endTime = block.timestamp + auction.extensionDuration;
        }
      }

      // Refund the previous bidder
      _sendValueWithFallbackWithdrawWithLowGasLimit(originalBidder, originalAmount);
    }

    emit ReserveAuctionBidPlaced(auctionId, msg.sender, amount, auction.endTime);
  }

  /**
   * @notice Once the countdown has expired for an auction, anyone can settle the auction.
   * This will send the NFT to the highest bidder and distribute funds.
   */
  function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    _finalizeReserveAuctionWithoutTransfer(auctionId, auction);
    IERC721(auction.nftContract).transferFrom(address(this), auction.bidder, auction.tokenId);
  }

  /**
   * @notice Returns the minimum amount a bidder must spend to participate in an auction.
   * Bids must be greater than or equal to this value or they will revert.
   */
  function getMinBidAmount(uint256 auctionId) external view returns (uint256) {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinIncrement(auction.amount);
  }

  /**
   * @notice Allows Foundation to cancel an auction, refunding the bidder and returning the NFT to
   * the seller (if not active buy price set).
   * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
   */
  function adminCancelReserveAuction(uint256 auctionId, string calldata reason) external onlyFoundationAdmin {
    if (bytes(reason).length == 0) {
      revert NFTMarketReserveAuction_Cannot_Admin_Cancel_Without_Reason();
    }
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    if (auction.amount == 0) {
      revert NFTMarketReserveAuction_Cannot_Cancel_Nonexistent_Auction();
    }

    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    if (!_hasBuyNowPrice(auction.nftContract, auction.tokenId, auction.seller)) {
      IERC721(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);
    }
    if (auction.bidder != address(0)) {
      _sendValueWithFallbackWithdrawWithMediumGasLimit(auction.bidder, auction.amount);
    }

    emit ReserveAuctionCanceledByAdmin(auctionId, reason);
  }

  /**
   * @notice Allows an NFT owner and Foundation to work together in order to update the seller
   * for auctions they have listed to a new account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   * @dev This will gracefully skip any auctions that have already been finalized.
   */
  function adminAccountMigration(
    uint256[] calldata listedAuctionIds,
    address originalAddress,
    address payable newAddress,
    bytes memory signature
  ) external onlyAuthorizedAccountMigration(originalAddress, newAddress, signature) {
    unchecked {
      for (uint256 i = 0; i < listedAuctionIds.length; i++) {
        uint256 auctionId = listedAuctionIds[i];
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        // The seller would be 0 if it was finalized before this call
        if (auction.seller != address(0)) {
          if (auction.seller != originalAddress) {
            revert NFTMarketReserveAuction_Cannot_Migrate_Non_Matching_Seller(auction.seller);
          }
          auction.seller = newAddress;
          emit ReserveAuctionSellerMigrated(auctionId, originalAddress, newAddress);
        }
      }
    }
  }

  function _finalizeReserveAuctionWithoutTransferWithReentrancyGuard(uint256 auctionId, ReserveAuction memory auction)
    private
    nonReentrant
  {
    _finalizeReserveAuctionWithoutTransfer(auctionId, auction);
  }

  function _finalizeReserveAuctionWithoutTransfer(uint256 auctionId, ReserveAuction memory auction) private {
    if (auction.endTime == 0) {
      revert NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
    }
    if (auction.endTime >= block.timestamp) {
      revert NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(auction.endTime);
    }

    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      auction.nftContract,
      auction.tokenId,
      auction.seller,
      auction.amount
    );

    emit ReserveAuctionFinalized(auctionId, auction.seller, auction.bidder, f8nFee, creatorFee, ownerRev);
  }

  /**
   * @dev Returns true if the NFT is available in auction and no bids have been placed yet.
   */
  function _hasAuctionReservePrice(address nftContract, uint256 tokenId) internal view override returns (bool) {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId != 0 && auctionIdToAuction[auctionId].endTime == 0) {
      return true;
    }
    return false;
  }

  /**
   * @dev Checks if an escrowed NFT is currently in active auction.
   * This returns false if the auction has ended, even if it has not yet been settled.
   */
  function _isInActiveAuction(address nftContract, uint256 tokenId) internal view override returns (bool) {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId == 0) {
      return false;
    }
    return auctionIdToAuction[auctionId].endTime >= block.timestamp;
  }

  /**
   * @dev Settles an auction if there was one which has already ended.
   * @return true if the auction was settled.
   */
  function _autoSettleAuctionAndTransfer(
    address nftContract,
    uint256 tokenId,
    address seller,
    address buyer
  ) internal override returns (bool) {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId == 0) {
      // No auction found
      return false;
    }
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      // Auction has not started
      return false;
    }
    if (auction.bidder != seller) {
      revert NFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
    }
    _finalizeReserveAuctionWithoutTransfer(auctionId, auction);
    IERC721(nftContract).transferFrom(address(this), buyer, tokenId);
    return true;
  }

  /**
   * @dev Clears auction status and emits a ReserveAuctionInvalidated on a buy now price met.
   */
  function _buyNowPriceMet(
    address nftContract,
    uint256 tokenId,
    address buyer
  ) internal virtual override {
    _invalidateAuction(nftContract, tokenId);
    super._buyNowPriceMet(nftContract, tokenId, buyer);
  }

  /**
   * @dev When an offer in escrow is accepted, we may need to invalidate the auction's reserve price.
   */
  function _offerAccepted(address nftContract, uint256 tokenId) internal virtual override {
    _invalidateAuction(nftContract, tokenId);
    super._offerAccepted(nftContract, tokenId);
  }

  /**
   * @dev Invalidates an auction if one is found.
   */
  function _invalidateAuction(address nftContract, uint256 tokenId) private {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId != 0) {
      delete nftContractToTokenIdToAuctionId[nftContract][tokenId];
      delete auctionIdToAuction[auctionId];
      emit ReserveAuctionInvalidated(auctionId);
    }
  }

  function _isAuctionEscrowSeller(
    address nftContract,
    uint256 tokenId,
    address seller,
    bool addReentrancyGuard
  ) internal override returns (bool) {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId == 0) {
      return false;
    }
    // Using storage saves gas since most of the data is not needed
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      // Reserve price set, confirm the seller is a match
      if (auction.seller != seller) {
        revert NFTMarketReserveAuction_Not_Matching_Seller(auction.seller);
      }
    } else {
      // Auction in progress, confirm the highest bidder is a match
      if (auction.bidder != seller) {
        revert NFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
      }

      // Finalize auction but leave NFT in escrow, reverts if the auction has not ended
      if (addReentrancyGuard) {
        _finalizeReserveAuctionWithoutTransferWithReentrancyGuard(auctionId, auction);
      } else {
        _finalizeReserveAuctionWithoutTransfer(auctionId, auction);
      }
    }
    return true;
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./NFTMarketFees.sol";

error NFTMarketPrivateSale_Proxy_Address_Is_Not_A_Contract();
error NFTMarketPrivateSale_Sale_Expired();
error NFTMarketPrivateSale_Signature_Verification_Failed();
error NFTMarketPrivateSale_Too_Much_Value_Provided();
error NFTMarketPrivateSale_Can_Be_Offered_For_24Hrs_Max();

/**
 * @notice Adds support for a private sale of an NFT directly between two parties.
 */
abstract contract NFTMarketPrivateSale is NFTMarketFees {
  using AddressUpgradeable for address;

  /**
   * @dev This name is used in the EIP-712 domain.
   * If multiple classes use EIP-712 signatures in the future this can move to the shared constants file.
   */
  string private constant NAME = "FNDNFTMarket";
  /**
   * @dev This is a hash of the method signature used in the EIP-712 signature for private sales.
   */
  bytes32 private constant BUY_FROM_PRIVATE_SALE_TYPEHASH =
    keccak256("BuyFromPrivateSale(address nftContract,uint256 tokenId,address buyer,uint256 price,uint256 deadline)");

  bytes32 private ____gap_was_DOMAIN_SEPARATOR;

  /**
   * @dev This is the domain used in EIP-712 signatures.
   * It is not a constant so that the chainId can be determined dynamically.
   * If multiple classes use EIP-712 signatures in the future this can move to a shared file.
   */
  bytes32 private immutable DOMAIN_SEPARATOR;

  event PrivateSaleFinalized(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev,
    uint256 deadline
  );

  constructor(address proxyAddress) {
    if (!proxyAddress.isContract()) {
      revert NFTMarketPrivateSale_Proxy_Address_Is_Not_A_Contract();
    }
    uint256 chainId;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(NAME)),
        keccak256(bytes("1")),
        chainId,
        proxyAddress
      )
    );
  }

  /**
   * @notice Allow two parties to execute a private sale.
   * @dev The seller signs a message approving the sale, and then the buyer calls this function
   * with the msg.value equal to the agreed upon price.
   * The sale is executed in this single on-chain call including the transfer of funds and the NFT.
   */
  function buyFromPrivateSale(
    IERC721 nftContract,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable {
    buyFromPrivateSaleFor(nftContract, tokenId, msg.value, deadline, v, r, s);
  }

  /**
   * @notice Allow two parties to execute a private sale.
   * @dev The seller signs a message approving the sale, and then the buyer calls this function
   * with the msg.value equal to the agreed upon price.
   * The sale is executed in this single on-chain call including the transfer of funds and the NFT.
   * @dev amount - msg.value is withdrawn from the bidder's FETH balance.
   */
  function buyFromPrivateSaleFor(
    IERC721 nftContract,
    uint256 tokenId,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable nonReentrant {
    // PrivateSale can be offered up to 2 days.
    if (deadline > block.timestamp + 2 days) {
      revert NFTMarketPrivateSale_Can_Be_Offered_For_24Hrs_Max();
    }
    if (amount > msg.value) {
      // The if above ensures delta will not underflow
      unchecked {
        uint256 delta = amount - msg.value;
        feth.marketWithdrawFrom(msg.sender, delta);
      }
    } else if (amount < msg.value) {
      revert NFTMarketPrivateSale_Too_Much_Value_Provided();
    }

    // The signed message from the seller is only valid for a limited time.
    if (deadline < block.timestamp) {
      revert NFTMarketPrivateSale_Sale_Expired();
    }
    // The seller must have the NFT in their wallet when this function is called.
    address payable seller = payable(nftContract.ownerOf(tokenId));

    // Scoping this block to avoid a stack too deep error
    {
      bytes32 digest = keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(BUY_FROM_PRIVATE_SALE_TYPEHASH, nftContract, tokenId, msg.sender, amount, deadline))
        )
      );
      // Revert if the signature is invalid, the terms are not as expected, or if the seller transferred the NFT.
      if (ecrecover(digest, v, r, s) != seller) {
        revert NFTMarketPrivateSale_Signature_Verification_Failed();
      }
    }

    // This will revert if the seller has not given the market contract approval.
    nftContract.transferFrom(seller, msg.sender, tokenId);
    // Pay the seller, creator, and Foundation as appropriate.
    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      address(nftContract),
      tokenId,
      seller,
      amount
    );

    emit PrivateSaleFinalized(
      address(nftContract),
      tokenId,
      seller,
      msg.sender,
      f8nFee,
      creatorFee,
      ownerRev,
      deadline
    );
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./Constants.sol";
import "./NFTMarketFees.sol";
import "./NFTMarketCore.sol";

/**
 * @notice Custom Errors defined for NFTMarketBuyNow.
 */
error NFTMarketBuyNow_Only_Owner_Can_Set_Price(address owner);
error NFTMarketBuyNow_Only_Owner_Can_Cancel_Price(address owner);
error NFTMarketBuyNow_Cannot_Buy_Unset_Price();
error NFTMarketBuyNow_Cannot_Buy_At_Lower_Price(uint256 buyNowPrice);
error NFTMarketBuyNow_Cannot_Cancel_Unset_Price();
error NFTMarketBuyNow_Price_Too_High();
error NFTMarketBuyNow_Seller_Mismatch(address seller);

/**
 * @notice Adds support for a buy now price for an NFT.
 */
abstract contract NFTMarketBuyNow is NFTMarketCore, NFTMarketFees {
  using AddressUpgradeable for address payable;

  struct BuyNow {
    address payable seller;
    uint96 amount;
  }

  mapping(address => mapping(uint256 => BuyNow)) private nftContractToTokenIdToBuyNow;

  event BuyPriceSet(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 amount);
  event BuyPriceCanceled(address indexed nftContract, uint256 indexed tokenId);
  event BuyPriceInvalidated(address indexed nftContract, uint256 indexed tokenId);
  event BuyPriceAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev
  );

  /**
   * @notice Set the buy now price for an NFT and escrows in the market.
   * @dev Setting a 0x0 address for the seller and 0 for amount will clear the set buy now state for the NFT;
   * however, will not remove the NFT from escrow.
   * The first bid that kicks off an auction also clears the buy now price for the NFT.
   */
  function setBuyPrice(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) external {
    if (amount > type(uint96).max) {
      revert NFTMarketBuyNow_Price_Too_High();
    }

    BuyNow storage buyNow = nftContractToTokenIdToBuyNow[nftContract][tokenId];
    buyNow.amount = uint96(amount);
    if (buyNow.seller == address(0)) {
      // New buy price
      buyNow.seller = payable(msg.sender);

      // Check existing escrow
      if (!_isAuctionEscrowSeller(nftContract, tokenId, msg.sender, true)) {
        // Escrow the NFT onto the FND Market
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
      }
    } else if (buyNow.seller != msg.sender) {
      // Buy price was previously set by a different user
      revert NFTMarketBuyNow_Only_Owner_Can_Set_Price(buyNow.seller);
    }

    emit BuyPriceSet(nftContract, tokenId, msg.sender, amount);
  }

  /**
   * @notice Buy the NFT at the set buy now price for the provided amount.
   */
  function buy(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) external payable {
    BuyNow memory curBuyNow = nftContractToTokenIdToBuyNow[nftContract][tokenId];
    if (amount < curBuyNow.amount) {
      revert NFTMarketBuyNow_Cannot_Buy_At_Lower_Price(curBuyNow.amount);
    }
    _buy(nftContract, tokenId, curBuyNow);
  }

  /**
   * @notice If the NFT has a buy now set and the seller match, clears buy now state for the NFT.
   * If the NFT is not listed in an auction, returns back the NFT to the original owner from escrow.
   */
  function cancelBuyPrice(address nftContract, uint256 tokenId) external nonReentrant {
    address seller = nftContractToTokenIdToBuyNow[nftContract][tokenId].seller;
    if (seller == address(0)) {
      revert NFTMarketBuyNow_Cannot_Cancel_Unset_Price();
    }
    if (seller != msg.sender) {
      revert NFTMarketBuyNow_Only_Owner_Can_Cancel_Price(seller);
    }

    // Transfer back NFT to owner.
    delete nftContractToTokenIdToBuyNow[nftContract][tokenId];
    // Make sure not escrowed for anything else before transferring NFT back to owner.
    if (!_hasAuctionReservePrice(nftContract, tokenId)) {
      IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    }

    emit BuyPriceCanceled(nftContract, tokenId);
  }

  /**
   * @notice Returns the buy price details for an NFT if one is available.
   * If no price is found, seller will be address(0) and amount will be max uint256.
   */
  function getBuyPrice(address nftContract, uint256 tokenId) external view returns (address seller, uint256 price) {
    BuyNow memory buyNow = nftContractToTokenIdToBuyNow[nftContract][tokenId];
    if (buyNow.seller == address(0)) {
      return (address(0), type(uint256).max);
    }
    return (buyNow.seller, buyNow.amount);
  }

  function _autoBuy(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) internal override returns (bool) {
    BuyNow memory curBuyNow = nftContractToTokenIdToBuyNow[nftContract][tokenId];
    if (curBuyNow.seller == address(0) || curBuyNow.amount > amount) {
      return false;
    }
    _buy(nftContract, tokenId, curBuyNow);
    return true;
  }

  function _buy(
    address nftContract,
    uint256 tokenId,
    BuyNow memory curBuyNow
  ) private nonReentrant {
    if (curBuyNow.seller == address(0)) {
      revert NFTMarketBuyNow_Cannot_Buy_Unset_Price();
    }

    if (curBuyNow.amount > msg.value) {
      // Withdraw delta funds from their available FETH balance
      unchecked {
        // The if above ensures delta will not underflow
        uint256 delta = curBuyNow.amount - msg.value;
        feth.marketWithdrawFrom(msg.sender, delta);
      }
    } else if (msg.value > curBuyNow.amount) {
      // return the surplus funds to the buyer.
      unchecked {
        // The if above ensures this will not underflow
        payable(msg.sender).sendValue(msg.value - curBuyNow.amount);
      }
    }

    // clear internal state.
    delete nftContractToTokenIdToBuyNow[nftContract][tokenId];

    // Notify implementors of _buyNowPriceMet on buy now.
    _buyNowPriceMet(nftContract, tokenId, msg.sender);
    // transfer NFT from escrow to msg.sender.
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

    // Pay the seller, creator and Foundation as appropriate.
    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      address(nftContract),
      tokenId,
      curBuyNow.seller,
      curBuyNow.amount
    );

    emit BuyPriceAccepted(nftContract, tokenId, curBuyNow.seller, msg.sender, f8nFee, creatorFee, ownerRev);
  }

  /**
   * @dev Returns the seller that put a given NFT into escrow,
   * or bubbles the call up to check the current owner if the NFT is not currently in escrow.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (address payable seller)
  {
    seller = nftContractToTokenIdToBuyNow[nftContract][tokenId].seller;
    if (seller == address(0)) {
      return super._getSellerFor(nftContract, tokenId);
    }
  }

  /**
   * @dev Returns true if the NFT has a valid buy now price set.
   * Reverts if there is a buy now price but the seller does not match.
   */
  function _hasBuyNowPrice(
    address nftContract,
    uint256 tokenId,
    address seller
  ) internal view override returns (bool) {
    address buySeller = nftContractToTokenIdToBuyNow[nftContract][tokenId].seller;
    if (buySeller == address(0)) {
      return false;
    }
    if (buySeller != seller) {
      revert NFTMarketBuyNow_Seller_Mismatch(buySeller);
    }
    return true;
  }

  /**
   * @dev Clears buy now price set and emits a BuyPriceInvalidated on a auction start.
   */
  function _auctionStarted(address nftContract, uint256 tokenId) internal virtual override {
    _invalidateBuyNow(nftContract, tokenId);
    super._auctionStarted(nftContract, tokenId);
  }

  /**
   * @dev Clears the buy now price set and emits a BuyPriceInvalidated when an escrowed NFT is purchased via offers.
   */
  function _offerAccepted(address nftContract, uint256 tokenId) internal virtual override {
    _invalidateBuyNow(nftContract, tokenId);
    super._offerAccepted(nftContract, tokenId);
  }

  /**
   * @dev Clear a buy now price and emit BuyPriceInvalidated if one is found.
   */
  function _invalidateBuyNow(address nftContract, uint256 tokenId) private {
    if (nftContractToTokenIdToBuyNow[nftContract][tokenId].seller != address(0)) {
      delete nftContractToTokenIdToBuyNow[nftContract][tokenId];
      emit BuyPriceInvalidated(nftContract, tokenId);
    }
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./NFTMarketFees.sol";
import "./NFTMarketCore.sol";
import "./roles/FoundationAdminRole.sol";
import "../FETH.sol";

error NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(uint256 minOfferAmount);
error NFTMarketOffer_Offer_Expired(uint256 expiry);
error NFTMarketOffer_Offer_Below_Min_Amount(uint256 currentOfferAmount);
error NFTMarketOffer_Reason_Required();
error NFTMarketOffer_In_Active_Auction();
error NFTMarketOffer_Only_Owner_Can_Accept(address owner);

/**
 * @notice Allows collectors to make an offer for an NFT, valid for 24-25 hours.
 * Funds are escrowed in the FETH contract.
 */
abstract contract NFTMarketOffer is FoundationAdminRole, NFTMarketCore, ReentrancyGuardUpgradeable, NFTMarketFees {
  using AddressUpgradeable for address;

  /// @dev Tracks the current highest offer for an NFT.
  struct Offer {
    // Slot 1: When increasing an offer, only this slot is updated.
    uint32 expiration;
    uint96 amount;
    // 128 bits are available in slot 1

    // Slot 2
    address buyer;
  }

  /// @dev Stores per-NFT offers.
  mapping(address => mapping(uint256 => Offer)) private nftContractToIdToOffer;

  event OfferMade(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 amount,
    uint256 expiration
  );
  event OfferAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    address seller,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev
  );
  event OfferInvalidated(address indexed nftContract, uint256 indexed tokenId);
  event OfferCanceledByAdmin(address indexed nftContract, uint256 indexed tokenId, string reason);

  /**
   * @notice Make an offer for any NFT, funds will be locked in FETH.
   * @dev An offer may be made for an NFT before it is minted.
   */
  function makeOffer(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) external payable {
    if (_isInActiveAuction(nftContract, tokenId)) {
      revert NFTMarketOffer_In_Active_Auction();
    }
    if (_autoBuy(nftContract, tokenId, amount)) {
      return;
    }
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];

    uint256 expiration;
    if (offer.expiration >= block.timestamp) {
      // A previous offer exists and has not expired

      if (amount < _getMinIncrement(offer.amount)) {
        // A non-trivial increase in price is required to avoid sniping
        revert NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(_getMinIncrement(offer.amount));
      }

      // Update escrow for the new offer
      expiration = feth.marketChangeDeposit{ value: msg.value }(
        offer.buyer,
        offer.expiration,
        offer.amount,
        msg.sender,
        amount
      );
    } else {
      // Else brand new offer

      // Add offer to escrow
      expiration = feth.marketDepositFor{ value: msg.value }(msg.sender, amount);
    }

    // Record offer details
    offer.buyer = msg.sender;
    offer.expiration = uint32(expiration);
    offer.amount = uint96(amount);
    emit OfferMade(nftContract, tokenId, msg.sender, amount, expiration);
  }

  /**
   * @notice Accept an offer for an NFT.
   * @dev The offer must not be expired and the NFT owned + approved by the seller or in available escrow.
   */
  function acceptOffer(
    address nftContract,
    uint256 tokenId,
    uint256 minAmount
  ) external nonReentrant {
    // Lookup and validate offer details
    Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration < block.timestamp) {
      revert NFTMarketOffer_Offer_Expired(offer.expiration);
    }
    if (offer.amount < minAmount) {
      revert NFTMarketOffer_Offer_Below_Min_Amount(offer.amount);
    }

    // Remove offer
    delete nftContractToIdToOffer[nftContract][tokenId];
    feth.marketWithdrawLocked(offer.buyer, offer.expiration, offer.amount);

    // Settle sale
    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      nftContract,
      tokenId,
      payable(msg.sender),
      offer.amount
    );
    try
      IERC721(nftContract).transferFrom(msg.sender, offer.buyer, tokenId) // solhint-disable-next-line no-empty-blocks
    {
      // Direct user to user transfer was successful
    } catch {
      // If the transfer fails then it might be in escrow
      if (!_autoSettleAuctionAndTransfer(nftContract, tokenId, msg.sender, offer.buyer)) {
        if (_getSellerFor(nftContract, tokenId) != msg.sender) {
          revert NFTMarketOffer_Only_Owner_Can_Accept(_getSellerFor(nftContract, tokenId));
        }
        // Inform escrow managers to clear their state
        _offerAccepted(nftContract, tokenId);
        IERC721(nftContract).transferFrom(address(this), offer.buyer, tokenId);
      }
    }

    emit OfferAccepted(nftContract, tokenId, offer.buyer, msg.sender, f8nFee, creatorFee, ownerRev);
  }

  /**
   * @notice Allows Foundation to cancel offers.
   * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
   */
  function adminCancelOffers(
    address[] calldata nftContracts,
    uint256[] calldata tokenIds,
    string calldata reason
  ) external onlyFoundationAdmin {
    if (bytes(reason).length == 0) {
      revert NFTMarketOffer_Reason_Required();
    }

    // The array length cannot overflow 256 bits
    unchecked {
      for (uint256 i = 0; i < nftContracts.length; i++) {
        Offer memory offer = nftContractToIdToOffer[nftContracts[i]][tokenIds[i]];
        delete nftContractToIdToOffer[nftContracts[i]][tokenIds[i]];

        if (offer.expiration >= block.timestamp) {
          // Unlock from escrow and emit an event only if the offer is still active
          feth.marketUnlockFor(offer.buyer, offer.expiration, offer.amount);
          emit OfferCanceledByAdmin(nftContracts[i], tokenIds[i], reason);
        }
        // Else continue on so the rest of the batch transaction can process successfully
      }
    }
  }

  /**
   * @dev Invalidates the offer when an auction is kicked off.
   */
  function _auctionStarted(address nftContract, uint256 tokenId) internal virtual override {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    _invalidateOffer(nftContract, tokenId, offer);
    super._auctionStarted(nftContract, tokenId);
  }

  /**
   * @dev Invalidates the offer when the offerer uses buy now instead.
   * If the offer is by a different user, it remains active for the new owner to consider.
   */
  function _buyNowPriceMet(
    address nftContract,
    uint256 tokenId,
    address buyer
  ) internal virtual override {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.buyer == buyer) {
      _invalidateOffer(nftContract, tokenId, offer);
    }
    super._buyNowPriceMet(nftContract, tokenId, buyer);
  }

  /**
   * @dev Invalidates the offer and frees from escrow if it is still active.
   */
  function _invalidateOffer(
    address nftContract,
    uint256 tokenId,
    Offer storage offer
  ) private {
    if (offer.expiration >= block.timestamp) {
      feth.marketUnlockFor(offer.buyer, offer.expiration, offer.amount);
      delete nftContractToIdToOffer[nftContract][tokenId];
      emit OfferInvalidated(nftContract, tokenId);
    }
  }

  /**
   * @notice Returns details about the current highest offer for an NFT.
   * @dev Nothing is returned if there is no offer or the offer has expired.
   */
  function getOffer(address nftContract, uint256 tokenId)
    external
    view
    returns (
      address buyer,
      uint256 expiration,
      uint256 amount
    )
  {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration >= block.timestamp) {
      return (offer.buyer, offer.expiration, offer.amount);
    }
    // Offer not found or has expired
    return (address(0), 0, 0);
  }

  /**
   * @notice Returns the minimum amount a collector must spend to place an offer.
   * Offers must be greater than or equal to this value or they will revert.
   */
  function getMinOfferAmount(address nftContract, uint256 tokenId) external view returns (uint256) {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration >= block.timestamp) {
      return _getMinIncrement(offer.amount);
    }
    // Absolute min is anything > 0
    return 1;
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAdminRole {
  function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IOperatorRole {
  function isOperator(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for functions the market uses in FETH.
 */
interface IFethMarket {
  function marketDepositFor(address account, uint256 amount) external payable returns (uint256 expiration);

  function marketWithdrawFrom(address from, uint256 amount) external;

  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) external;

  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) external;

  function marketChangeDeposit(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address depositFor,
    uint256 depositAmount
  ) external payable returns (uint256 expiration);
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

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable

pragma solidity ^0.8.0;

interface IFNDNFT721 {
  function tokenCreator(uint256 tokenId) external view returns (address payable);

  function getTokenCreatorPaymentAddress(uint256 tokenId) external view returns (address payable);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ITokenCreator {
  function tokenCreator(uint256 tokenId) external view returns (address payable);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IGetRoyalties {
  function getRoyalties(uint256 tokenId)
    external
    view
    returns (address payable[] memory recipients, uint256[] memory feesInBasisPoints);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice An interface for communicating fees to 3rd party marketplaces.
 * @dev Originally implemented in mainnet contract 0x44d6e8933f8271abcf253c72f9ed7e0e4c0323b3
 */
interface IGetFees {
  function getFeeRecipients(uint256 id) external view returns (address payable[] memory);

  function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for EIP-2981: NFT Royalty Standard.
 * For more see: https://eips.ethereum.org/EIPS/eip-2981.
 */
interface IRoyaltyInfo {
  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _salePrice
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Royalty registry interface
 */
interface IRoyaltyRegistry is IERC165 {

     event RoyaltyOverride(address owner, address tokenAddress, address royaltyAddress);

    /**
     * Override the location of where to look up royalty information for a given token contract.
     * Allows for backwards compatibility and implementation of royalty logic for contracts that did not previously support them.
     * 
     * @param tokenAddress    - The token address you wish to override
     * @param royaltyAddress  - The royalty override address
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyAddress) external;

    /**
     * Returns royalty address location.  Returns the tokenAddress by default, or the override if it exists
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function getRoyaltyLookupAddress(address tokenAddress) external view returns(address);

    /**
     * Whether or not the message sender can override the royalty address for the given token address
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function overrideAllowed(address tokenAddress) external view returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/introspection/ERC165.sol
 * Modified to allow checking multiple interfaces w/o checking general 165 support.
 */

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
  // As per the EIP-165 spec, no interface should ever match 0xffffffff
  bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

  /**
   * @dev Returns true if `account` supports the {IERC165} interface,
   */
  function supportsERC165(address account) internal view returns (bool) {
    // Any contract that implements ERC165 must explicitly indicate support of
    // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
    return
      supportsERC165Interface(account, type(IERC165).interfaceId) &&
      !supportsERC165Interface(account, _INTERFACE_ID_INVALID);
  }

  /**
   * @dev Returns true if `account` supports the interface defined by
   * `interfaceId`. Support for {IERC165} itself is queried automatically.
   *
   * See {IERC165-supportsInterface}.
   */
  function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
    // query support of both ERC165 as per the spec and support of _interfaceId
    return supportsERC165(account) && supportsERC165Interface(account, interfaceId);
  }

  /**
   * @dev Returns a boolean array where each value corresponds to the
   * interfaces passed in and whether they're supported or not. This allows
   * you to batch check interfaces for a contract where your expectation
   * is that some interfaces may not be supported.
   *
   * See {IERC165-supportsInterface}.
   *
   * _Available since v3.4._
   */
  function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
    // an array of booleans corresponding to interfaceIds and whether they're supported or not
    bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

    // query support of ERC165 itself
    if (supportsERC165(account)) {
      // query support of each interface in interfaceIds
      unchecked {
        for (uint256 i = 0; i < interfaceIds.length; i++) {
          interfaceIdsSupported[i] = supportsERC165Interface(account, interfaceIds[i]);
        }
      }
    }

    return interfaceIdsSupported;
  }

  /**
   * @dev Returns true if `account` supports all the interfaces defined in
   * `interfaceIds`. Support for {IERC165} itself is queried automatically.
   *
   * Batch-querying can lead to gas savings by skipping repeated checks for
   * {IERC165} support.
   *
   * See {IERC165-supportsInterface}.
   */
  function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
    // query support of ERC165 itself
    if (!supportsERC165(account)) {
      return false;
    }

    // query support of each interface in _interfaceIds
    unchecked {
      for (uint256 i = 0; i < interfaceIds.length; i++) {
        if (!supportsERC165Interface(account, interfaceIds[i])) {
          return false;
        }
      }
    }

    // all interfaces supported
    return true;
  }

  /**
   * @notice Query if a contract implements an interface, does not check ERC165 support
   * @param account The address of the contract to query for support of an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @return true if the contract at account indicates support of the interface with
   * identifier interfaceId, false otherwise
   * @dev Assumes that account contains a contract that supports ERC165, otherwise
   * the behavior of this method is undefined. This precondition can be checked
   * with {supportsERC165}.
   * Interface identification is specified in ERC-165.
   */
  function supportsERC165Interface(address account, bytes4 interfaceId) internal view returns (bool) {
    bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
    (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
    if (result.length < 32) return false;
    return success && abi.decode(result, (bool));
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../libraries/AccountMigrationLibrary.sol";
import "./roles/FoundationOperatorRole.sol";

error AccountMigration_Caller_Is_Not_Operator();

abstract contract AccountMigration is FoundationOperatorRole {
  using AccountMigrationLibrary for address;

  modifier onlyAuthorizedAccountMigration(
    address originalAddress,
    address payable newAddress,
    bytes memory signature
  ) {
    if (!_isFoundationOperator()) {
      revert AccountMigration_Caller_Is_Not_Operator();
    }
    originalAddress.requireAuthorizedAccountMigration(newAddress, signature);
    _;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error AccountMigrationLibrary_Cannot_Migrate_Account_To_Itself();
error AccountMigrationLibrary_Signature_Verification_Failed();

/**
 * @notice Checks for a valid signature authorizing the migration of an account to a new address.
 * @dev This is shared by both the NFT contracts and FNDNFTMarket, and the same signature authorizes both.
 */
library AccountMigrationLibrary {
  using ECDSA for bytes;
  using SignatureChecker for address;
  using Strings for uint256;

  // From https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
  function _toAsciiString(address x) private pure returns (string memory) {
    unchecked {
      bytes memory s = new bytes(42);
      s[0] = "0";
      s[1] = "x";
      for (uint256 i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2 * i + 2] = _char(hi);
        s[2 * i + 3] = _char(lo);
      }
      return string(s);
    }
  }

  function _char(bytes1 b) private pure returns (bytes1 c) {
    unchecked {
      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
    }
  }

  /**
   * @dev Confirms the msg.sender is a Foundation operator and that the signature provided is valid.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function requireAuthorizedAccountMigration(
    address originalAddress,
    address newAddress,
    bytes memory signature
  ) internal view {
    if (originalAddress == newAddress) {
      revert AccountMigrationLibrary_Cannot_Migrate_Account_To_Itself();
    }
    bytes32 hash = abi
      .encodePacked("I authorize Foundation to migrate my account to ", _toAsciiString(newAddress))
      .toEthSignedMessageHash();
    if (!originalAddress.isValidSignatureNow(hash, signature)) {
      revert AccountMigrationLibrary_Signature_Verification_Failed();
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IFethMarket.sol";
import "./libraries/LockedBalance.sol";

error FETH_Invalid_Lockup_Duration();
error FETH_Expiration_Too_Far_In_Future();
error FETH_Only_FND_Market_Allowed();
error FETH_No_Funds_To_Withdraw();
error FETH_Market_Must_Be_A_Contract();
error FETH_Transfer_To_Burn_Not_Allowed();
error FETH_Insufficient_Allowance(uint256 amount);
error FETH_Insufficient_Available_Funds(uint256 amount);
error FETH_Escrow_Expired();
error FETH_Insufficient_Escrow(uint256 amount);
error FETH_Can_Not_Deposit_For_Lockup_with_Address_Zero();
error FETH_Must_Deposit_Positive_Amount();
error FETH_Must_Deposit_Exact_Amount();
error FETH_Escrow_Not_Found();

/**
 * @notice An ERC-20 token which wraps ETH, potentially with a 1 day lockup period.
 */
contract FETH is IFethMarket {
  using AddressUpgradeable for address payable;
  using Math for uint256;
  using LockedBalance for LockedBalance.Lockups;
  /// @dev Tracks an account's info.
  struct AccountInfo {
    /// @dev The amount of ETH which has been unlocked already.
    uint96 freedBalance;
    /// @dev The first applicable lockup bucket for this account.
    uint32 lockupStartIndex;
    /// @dev Stores up to 25 buckets of locked balance for a user, one per hour.
    LockedBalance.Lockups lockups;
    /// @dev Returns the amount which a spender is still allowed to withdraw from this account.
    mapping(address => uint256) allowance;
  }

  // ERC-20 metadata fields
  string public constant name = "Foundation Wrapped Ether";
  string public constant symbol = "FETH";
  uint8 public constant decimals = 18;

  // Lockup configuration
  /// @notice The minimum lockup period in seconds.
  uint256 private immutable lockupDuration;
  /// @notice The interval to which lockup expiries are rounded, limiting the max number of outstanding lockup buckets.
  uint256 private immutable lockupInterval;

  /// @notice The Foundation market contract with permissions to manage lockups.
  address payable public immutable foundationMarket;

  /// @dev Stores per-account details.
  mapping(address => AccountInfo) private accountToInfo;

  // ERC-20 events
  event Approval(address indexed from, address indexed spender, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);

  // Custom events
  event ETHWithdrawn(address indexed from, address indexed to, uint256 amount);
  event BalanceLocked(address indexed account, uint256 indexed expiration, uint256 amount);
  event BalanceUnlocked(address indexed account, uint256 indexed expiration, uint256 amount);

  /// @dev Allows the Foundation market permission to manage lockups for a user.
  modifier onlyFoundationMarket() {
    if (msg.sender != foundationMarket) {
      revert FETH_Only_FND_Market_Allowed();
    }
    _;
  }

  constructor(address payable _foundationMarket, uint256 _lockupDuration) {
    if (!_foundationMarket.isContract()) {
      revert FETH_Market_Must_Be_A_Contract();
    }
    foundationMarket = _foundationMarket;
    lockupDuration = _lockupDuration;
    lockupInterval = _lockupDuration / 24;
    if (lockupInterval * 24 != _lockupDuration || _lockupDuration == 0) {
      revert FETH_Invalid_Lockup_Duration();
    }
  }

  /**
   * @notice Transferring ETH to the contract performs a deposit.
   */
  receive() external payable {
    deposit();
  }

  /**
   * @notice Deposit ETH and receive FETH which is not subject to any lockup period.
   */
  function deposit() public payable {
    AccountInfo storage accountInfo = accountToInfo[msg.sender];
    // ETH value cannot realistically overflow 96 bits
    unchecked {
      accountInfo.freedBalance += uint96(msg.value);
    }
    emit Transfer(address(0), msg.sender, msg.value);
  }

  /**
   * @notice Used by the market contract:
   * Adds funds to an account which are locked for a period of time.
   */
  function marketDepositFor(address account, uint256 amount)
    external
    payable
    onlyFoundationMarket
    returns (uint256 expiration)
  {
    return _marketDepositFor(account, amount);
  }

  /**
   * @notice Used by the market contract:
   * Removes available balance and returns ETH to the caller.
   */
  function marketWithdrawFrom(address from, uint256 amount) external onlyFoundationMarket {
    AccountInfo storage accountInfo = _freeFromEscrow(from);
    _deductFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(from, msg.sender, amount);
  }

  /**
   * @notice Used by the market contract:
   * Removes an account's lockup and returns ETH to the caller.
   */
  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) external onlyFoundationMarket {
    _removeFromLockedBalance(account, expiration, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(account, msg.sender, amount);
  }

  /**
   * @notice Used by the market contract:
   * Remove an account's lockup, making the ETH available.
   */
  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) external onlyFoundationMarket {
    _marketUnlockFor(account, expiration, amount);
  }

  /**
   * @notice Used by the market contract:
   * Remove an account's lockup and deposit a new one, any surplus becomes available.
   */
  function marketChangeDeposit(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address depositFor,
    uint256 depositAmount
  ) external payable onlyFoundationMarket returns (uint256 expiration) {
    _marketUnlockFor(unlockFrom, unlockExpiration, unlockAmount);
    return _marketDepositFor(depositFor, depositAmount);
  }

  /**
   * @notice Withdraw all ETH available to your account.
   */
  function withdrawAvailableBalance() external {
    AccountInfo storage accountInfo = _freeFromEscrow(msg.sender);
    uint256 amount = accountInfo.freedBalance;
    if (amount == 0) {
      revert FETH_No_Funds_To_Withdraw();
    }
    delete accountInfo.freedBalance;

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(msg.sender, msg.sender, amount);
  }

  /**
   * @notice Withdraw the specified amount and sends ETH to the destination address.
   */
  function withdrawFrom(
    address from,
    address payable to,
    uint256 amount
  ) external {
    if (amount == 0) {
      revert FETH_No_Funds_To_Withdraw();
    }
    AccountInfo storage accountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowance(accountInfo, amount);
    }
    _deductFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    to.sendValue(amount);

    emit ETHWithdrawn(from, to, amount);
  }

  /**
   * @notice Approves the spender to transfer from your account.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    accountToInfo[msg.sender].allowance[spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Transfers an amount from your account.
   */
  function transfer(address to, uint256 amount) external returns (bool) {
    return transferFrom(msg.sender, to, amount);
  }

  /**
   * @notice Transfers an amount from the account specified.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public returns (bool) {
    if (to == address(0) || to == address(this)) {
      revert FETH_Transfer_To_Burn_Not_Allowed();
    }
    AccountInfo storage fromAccountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowance(fromAccountInfo, amount);
    }
    _deductFrom(fromAccountInfo, amount);
    AccountInfo storage toAccountInfo = accountToInfo[to];

    // Total ETH cannot realistically overflow 96 bits
    unchecked {
      toAccountInfo.freedBalance += uint96(amount);
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /**
   * @dev Require msg.sender has been approved and deducts the amount from the available allowance.
   */
  function _deductAllowance(AccountInfo storage accountInfo, uint256 amount) private {
    if (accountInfo.allowance[msg.sender] != type(uint256).max) {
      if (accountInfo.allowance[msg.sender] < amount) {
        revert FETH_Insufficient_Allowance(accountInfo.allowance[msg.sender]);
      }
      // The require ensures allowance cannot underflow
      unchecked {
        accountInfo.allowance[msg.sender] -= amount;
      }
    }
  }

  /**
   * @dev Removes an amount from the account's available funds.
   */
  function _deductFrom(AccountInfo storage accountInfo, uint256 amount) private {
    // Free from escrow in order to consider any expired escrow balance
    if (accountInfo.freedBalance < amount) {
      revert FETH_Insufficient_Available_Funds(accountInfo.freedBalance);
    }
    // The check above ensures balance cannot underflow
    unchecked {
      accountInfo.freedBalance -= uint96(amount);
    }
  }

  /**
   * @dev Moves expired escrow to the available balance.
   */
  function _freeFromEscrow(address account) private returns (AccountInfo storage) {
    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

    // If the first bucket is not ready to be freed, no change to escrowStartIndex is required
    if (escrow.expiration == 0) {
      return accountInfo;
    }
    if (escrow.expiration >= block.timestamp) {
      return accountInfo;
    }

    while (true) {
      // Total ETH will not realistically overflow 96 bits
      unchecked {
        accountInfo.freedBalance += escrow.totalAmount;
        accountInfo.lockups.del(escrowIndex);
        escrow = accountInfo.lockups.get(escrowIndex + 1);
      }

      // If the next bucket is empty, the start index is set to the previous bucket
      if (escrow.expiration == 0) {
        break;
      }

      unchecked {
        // Increment the escrow start index if the next bucket is not empty
        escrowIndex++;
      }

      // If the next bucket is expired, that's the new start index
      if (escrow.expiration >= block.timestamp) {
        break;
      }
    }

    // Escrow index will not realistically overflow 32 bits
    unchecked {
      accountInfo.lockupStartIndex = uint32(escrowIndex);
    }
    return accountInfo;
  }

  /**
   * @dev Removes the specified amount from locked escrow, potentially before its expiration.
   */
  /* solhint-disable-next-line code-complexity */
  function _removeFromLockedBalance(
    address account,
    uint256 expiration,
    uint256 amount
  ) private returns (AccountInfo storage) {
    if (expiration < block.timestamp) {
      revert FETH_Escrow_Expired();
    }

    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

    if (escrow.expiration == expiration) {
      // If removing from the first bucket, we may be able to delete it
      if (escrow.totalAmount == amount) {
        accountInfo.lockups.del(escrowIndex);

        // Bump the escrow start index unless it's the last one
        if (accountInfo.lockups.get(escrowIndex + 1).expiration != 0) {
          // The number of escrow buckets will never overflow 32 bits
          unchecked {
            accountInfo.lockupStartIndex++;
          }
        }
      } else {
        if (escrow.totalAmount < amount) {
          revert FETH_Insufficient_Escrow(escrow.totalAmount);
        }
        // The require above ensures balance will not underflow
        unchecked {
          accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
        }
      }
    } else {
      // Removing from the 2nd+ bucket
      while (true) {
        // The number of escrow buckets will never overflow 32 bits
        unchecked {
          escrowIndex++;
        }
        escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == expiration) {
          if (amount > escrow.totalAmount) {
            revert FETH_Insufficient_Escrow(escrow.totalAmount);
          }
          // The require above ensures balance will not underflow
          unchecked {
            accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
          }
          // We may have an entry with 0 totalAmount but expiration will be set
          break;
        }
        if (escrow.expiration == 0) {
          revert FETH_Escrow_Not_Found();
        }
      }
    }

    emit BalanceUnlocked(account, expiration, amount);
    return accountInfo;
  }

  function _marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) private {
    AccountInfo storage accountInfo = _removeFromLockedBalance(account, expiration, amount);
    // Total ETH cannot realistically overflow 96 bits
    unchecked {
      accountInfo.freedBalance += uint96(amount);
    }
  }

  /* solhint-disable-next-line code-complexity */
  function _marketDepositFor(address account, uint256 amount) private returns (uint256 expiration) {
    if (account == address(0)) {
      revert FETH_Can_Not_Deposit_For_Lockup_with_Address_Zero();
    }
    if (amount == 0) {
      revert FETH_Must_Deposit_Positive_Amount();
    }

    // Block timestamp in seconds is small enough to never overflow
    unchecked {
      // Lockup expires after 24 hours, rounded up to the next hour for a total of [24-25) hours
      expiration = lockupDuration + block.timestamp.ceilDiv(lockupInterval) * lockupInterval;
    }

    // Update available escrow
    // Always free from escrow to ensure the max bucket count is <= 25
    AccountInfo storage accountInfo = _freeFromEscrow(account);
    if (msg.value < amount) {
      // The if above prevents underflow with delta, and the require prevents underflow of freed balance
      unchecked {
        uint256 delta = amount - msg.value;
        if (accountInfo.freedBalance < delta) {
          revert FETH_Insufficient_Available_Funds(accountInfo.freedBalance);
        }
        accountInfo.freedBalance -= uint96(delta);
      }
    } else if (msg.value != amount) {
      revert FETH_Must_Deposit_Exact_Amount();
    }

    // Add to locked escrow
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          if (expiration > type(uint32).max) {
            revert FETH_Expiration_Too_Far_In_Future();
          }
          // Amount (ETH) will always be < 96 bits
          accountInfo.lockups.set(escrowIndex, expiration, amount);
          break;
        }
        if (escrow.expiration == expiration) {
          // Total ETH will always be < 96 bits
          accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount + amount);
          break;
        }
      }
    }

    emit BalanceLocked(account, expiration, amount);
  }

  /**
   * @notice Returns the total amount of ETH locked in this contract.
   */
  function totalSupply() external view returns (uint256) {
    /* It is possible for this to diverge from the total token count by transferring ETH on self destruct
       but this is on-par with the WETH implementation and done for gas savings. */
    return address(this).balance;
  }

  /**
   * @notice Returns the amount which a spender is still allowed to withdraw from the owner.
   */
  function allowance(address account, address operator) public view returns (uint256) {
    AccountInfo storage accountInfo = accountToInfo[account];
    return accountInfo.allowance[operator];
  }

  /**
   * @notice Returns the balance of an account, available to transfer or withdraw.
   */
  function balanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits
    unchecked {
      // Add expired lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Returns the total balance of an account, including locked up funds.
   */
  function totalBalanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits
    unchecked {
      // Add all lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Returns the configuration which is applied when balance is locked.
   */
  function getLockupConfiguration() external view returns (uint256 duration, uint256 interval) {
    return (lockupDuration, lockupInterval);
  }

  /**
   * @notice Returns the balance and each outstanding lockup bucket for an account.
   */
  function getLockups(address account) external view returns (uint256[] memory expiries, uint256[] memory amounts) {
    AccountInfo storage accountInfo = accountToInfo[account];

    // Count lockups
    uint256 lockedCount;
    // The number of buckets is always < 256 bits
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        if (escrow.expiration >= block.timestamp && escrow.totalAmount > 0) {
          lockedCount++;
        }
      }
    }

    // Allocate arrays
    expiries = new uint256[](lockedCount);
    amounts = new uint256[](lockedCount);

    // Populate results
    uint256 i;
    // The number of buckets is always < 256 bits
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        if (escrow.expiration >= block.timestamp && escrow.totalAmount > 0) {
          expiries[i] = escrow.expiration;
          amounts[i] = escrow.totalAmount;
          i++;
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

library LockedBalance {
  /// @dev Tracks an account's total lockup per expiration time.
  struct Lockup {
    uint32 expiration;
    uint96 totalAmount;
  }

  struct Lockups {
    mapping(uint256 => uint256) lockups;
  }

  uint256 private constant last128BitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant first128BitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000;

  uint256 private constant firstAmountBitsMask = 0xFFFFFFFF000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant secondAmountBitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000;

  function get(Lockups storage lockups, uint256 index) internal view returns (Lockup memory) {
    unchecked {
      uint256 lockupMetadata = lockups.lockups[index / 2];
      Lockup memory balance;
      if (lockupMetadata == 0) {
        return balance;
      }
      uint128 lockedBalanceBits;
      if (index % 2 == 0) {
        lockedBalanceBits = uint128(lockupMetadata >> 128);
      } else {
        lockedBalanceBits = uint128(lockupMetadata % (2**128));
      }
      balance.expiration = uint32(lockedBalanceBits >> 96);
      balance.totalAmount = uint96(lockedBalanceBits % (2**96));
      return balance;
    }
  }

  function set(
    Lockups storage lockups,
    uint256 index,
    uint256 expiration,
    uint256 totalAmount
  ) internal {
    unchecked {
      uint256 lockedBalanceBits = totalAmount | (expiration << 96);
      if (index % 2 == 0) {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & last128BitsMask) | (lockedBalanceBits << 128);
      } else {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & first128BitsMask) | lockedBalanceBits;
      }
    }
  }

  function setTotalAmount(
    Lockups storage lockups,
    uint256 index,
    uint256 totalAmount
  ) internal {
    unchecked {
      if (index % 2 == 0) {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & firstAmountBitsMask) | (totalAmount << 128);
      } else {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & secondAmountBitsMask) | totalAmount;
      }
    }
  }

  function del(Lockups storage lockups, uint256 index) internal {
    unchecked {
      if (index % 2 == 0) {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & last128BitsMask);
      } else {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & first128BitsMask);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IERC20Approve {
  function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

error BytesLibrary_Expected_Address_Not_Found();

/**
 * @notice A library for manipulation of byte arrays.
 */
library BytesLibrary {
  /**
   * @dev Replace the address at the given location in a byte array if the contents at that location
   * match the expected address.
   */
  function replaceAtIf(
    bytes memory data,
    uint256 startLocation,
    address expectedAddress,
    address newAddress
  ) internal pure {
    bytes memory expectedData = abi.encodePacked(expectedAddress);
    bytes memory newData = abi.encodePacked(newAddress);
    unchecked {
      // An address is 20 bytes long
      for (uint256 i = 0; i < 20; i++) {
        uint256 dataLocation = startLocation + i;
        if (data[dataLocation] != expectedData[i]) {
          revert BytesLibrary_Expected_Address_Not_Found();
        }
        data[dataLocation] = newData[i];
      }
    }
  }

  /**
   * @dev Checks if the call data starts with the given function signature.
   */
  function startsWith(bytes memory callData, bytes4 functionSig) internal pure returns (bool) {
    // A signature is 4 bytes long
    if (callData.length < 4) {
      return false;
    }
    unchecked {
      for (uint256 i = 0; i < 4; i++) {
        if (callData[i] != functionSig[i]) {
          return false;
        }
      }
    }

    return true;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ICollectionContractInitializer {
  function initialize(
    address payable _creator,
    string memory _name,
    string memory _symbol
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./IRoles.sol";
import "./IProxyCall.sol";

interface ICollectionFactory {
  function rolesContract() external returns (IRoles);

  function proxyCallContract() external returns (IProxyCall);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IProxyCall {
  function proxyCallAndReturnAddress(address externalContract, bytes memory callData)
    external
    returns (address payable result);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../interfaces/IProxyCall.sol";

/**
 * @notice Forwards arbitrary calls to an external contract to be processed.
 * @dev This is used so that the from address of the calling contract does not have
 * any special permissions (e.g. ERC-20 transfer).
 */
library ProxyCall {
  using AddressUpgradeable for address payable;

  /**
   * @dev Used by other mixins to make external calls through the proxy contract.
   * This will fail if the proxyCall address is address(0).
   */
  function proxyCallAndReturnContractAddress(
    IProxyCall proxyCall,
    address externalContract,
    bytes memory callData
  ) internal returns (address payable result) {
    result = proxyCall.proxyCallAndReturnAddress(externalContract, callData);
    require(result.isContract(), "ProxyCall: address returned is not a contract");
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for a contract which implements admin roles.
 */
interface IRoles {
  function isAdmin(address account) external view returns (bool);

  function isOperator(address account) external view returns (bool);
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    mapping(address => bool) public controllers;

    event ControllerChanged(address indexed controller, bool enabled);

    modifier onlyController {
        require(
            controllers[msg.sender],
            "Controllable: Caller is not a controller"
        );
        _;
    }

    function setController(address controller, bool enabled) public onlyOwner {
        controllers[controller] = enabled;
        emit ControllerChanged(controller, enabled);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

abstract contract ABIResolver is IABIResolver, ResolverBase {
    mapping(bytes32=>mapping(uint256=>bytes)) abis;

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) virtual external authorised(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);

        abis[node][contentType] = data;
        emit ABIChanged(node, contentType);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) virtual override external view returns (uint256, bytes memory) {
        mapping(uint256=>bytes) storage abiset = abis[node];

        for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && abiset[contentType].length > 0) {
                return (contentType, abiset[contentType]);
            }
        }

        return (0, bytes(""));
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IABIResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./IAddrResolver.sol";
import "./IAddressResolver.sol";

abstract contract AddrResolver is IAddrResolver, IAddressResolver, ResolverBase {
    uint constant private COIN_TYPE_ETH = 60;

    mapping(bytes32=>mapping(uint=>bytes)) _addresses;

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) virtual external authorised(node) {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) virtual override public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if(a.length == 0) {
            return payable(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) virtual public authorised(node) {
        emit AddressChanged(node, coinType, a);
        if(coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint coinType) virtual override public view returns(bytes memory) {
        return _addresses[node][coinType];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IAddrResolver).interfaceId || interfaceID == type(IAddressResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./IContentHashResolver.sol";

abstract contract ContentHashResolver is IContentHashResolver, ResolverBase {
    mapping(bytes32=>bytes) hashes;

    /**
     * Sets the contenthash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash) virtual external authorised(node) {
        hashes[node] = hash;
        emit ContenthashChanged(node, hash);
    }

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) virtual external override view returns (bytes memory) {
        return hashes[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IContentHashResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "../../dnssec-oracle/RRUtils.sol";
import "./IDNSRecordResolver.sol";
import "./IDNSZoneResolver.sol";

abstract contract DNSResolver is IDNSRecordResolver, IDNSZoneResolver, ResolverBase {
    using RRUtils for *;
    using BytesUtils for bytes;

    // Zone hashes for the domains.
    // A zone hash is an EIP-1577 content hash in binary format that should point to a
    // resource containing a single zonefile.
    // node => contenthash
    mapping(bytes32=>bytes) private zonehashes;

    // Version the mapping for each zone.  This allows users who have lost
    // track of their entries to effectively delete an entire zone by bumping
    // the version number.
    // node => version
    mapping(bytes32=>uint256) private versions;

    // The records themselves.  Stored as binary RRSETs
    // node => version => name => resource => data
    mapping(bytes32=>mapping(uint256=>mapping(bytes32=>mapping(uint16=>bytes)))) private records;

    // Count of number of entries for a given name.  Required for DNS resolvers
    // when resolving wildcards.
    // node => version => name => number of records
    mapping(bytes32=>mapping(uint256=>mapping(bytes32=>uint16))) private nameEntriesCount;

    /**
     * Set one or more DNS records.  Records are supplied in wire-format.
     * Records with the same node/name/resource must be supplied one after the
     * other to ensure the data is updated correctly. For example, if the data
     * was supplied:
     *     a.example.com IN A 1.2.3.4
     *     a.example.com IN A 5.6.7.8
     *     www.example.com IN CNAME a.example.com.
     * then this would store the two A records for a.example.com correctly as a
     * single RRSET, however if the data was supplied:
     *     a.example.com IN A 1.2.3.4
     *     www.example.com IN CNAME a.example.com.
     *     a.example.com IN A 5.6.7.8
     * then this would store the first A record, the CNAME, then the second A
     * record which would overwrite the first.
     *
     * @param node the namehash of the node for which to set the records
     * @param data the DNS wire format records to set
     */
    function setDNSRecords(bytes32 node, bytes calldata data) virtual external authorised(node) {
        uint16 resource = 0;
        uint256 offset = 0;
        bytes memory name;
        bytes memory value;
        bytes32 nameHash;
        // Iterate over the data to add the resource records
        for (RRUtils.RRIterator memory iter = data.iterateRRs(0); !iter.done(); iter.next()) {
            if (resource == 0) {
                resource = iter.dnstype;
                name = iter.name();
                nameHash = keccak256(abi.encodePacked(name));
                value = bytes(iter.rdata());
            } else {
                bytes memory newName = iter.name();
                if (resource != iter.dnstype || !name.equals(newName)) {
                    setDNSRRSet(node, name, resource, data, offset, iter.offset - offset, value.length == 0);
                    resource = iter.dnstype;
                    offset = iter.offset;
                    name = newName;
                    nameHash = keccak256(name);
                    value = bytes(iter.rdata());
                }
            }
        }
        if (name.length > 0) {
            setDNSRRSet(node, name, resource, data, offset, data.length - offset, value.length == 0);
        }
    }

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) virtual override public view returns (bytes memory) {
        return records[node][versions[node]][name][resource];
    }

    /**
     * Check if a given node has records.
     * @param node the namehash of the node for which to check the records
     * @param name the namehash of the node for which to check the records
     */
    function hasDNSRecords(bytes32 node, bytes32 name) virtual public view returns (bool) {
        return (nameEntriesCount[node][versions[node]][name] != 0);
    }

    /**
     * Clear all information for a DNS zone.
     * @param node the namehash of the node for which to clear the zone
     */
    function clearDNSZone(bytes32 node) virtual public authorised(node) {
        versions[node]++;
        emit DNSZoneCleared(node);
    }

    /**
     * setZonehash sets the hash for the zone.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The zonehash to set
     */
    function setZonehash(bytes32 node, bytes calldata hash) virtual external authorised(node) {
        bytes memory oldhash = zonehashes[node];
        zonehashes[node] = hash;
        emit DNSZonehashChanged(node, oldhash, hash);
    }

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) virtual override external view returns (bytes memory) {
        return zonehashes[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IDNSRecordResolver).interfaceId ||
               interfaceID == type(IDNSZoneResolver).interfaceId ||
               super.supportsInterface(interfaceID);
    }

    function setDNSRRSet(
        bytes32 node,
        bytes memory name,
        uint16 resource,
        bytes memory data,
        uint256 offset,
        uint256 size,
        bool deleteRecord) private
    {
        uint256 version = versions[node];
        bytes32 nameHash = keccak256(name);
        bytes memory rrData = data.substring(offset, size);
        if (deleteRecord) {
            if (records[node][version][nameHash][resource].length != 0) {
                nameEntriesCount[node][version][nameHash]--;
            }
            delete(records[node][version][nameHash][resource]);
            emit DNSRecordDeleted(node, name, resource);
        } else {
            if (records[node][version][nameHash][resource].length == 0) {
                nameEntriesCount[node][version][nameHash]++;
            }
            records[node][version][nameHash][resource] = rrData;
            emit DNSRecordChanged(node, name, resource, rrData);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "../ISupportsInterface.sol";
import "./AddrResolver.sol";
import "./IInterfaceResolver.sol";

abstract contract InterfaceResolver is IInterfaceResolver, AddrResolver {
    mapping(bytes32=>mapping(bytes4=>address)) interfaces;

    /**
     * Sets an interface associated with a name.
     * Setting the address to 0 restores the default behaviour of querying the contract at `addr()` for interface support.
     * @param node The node to update.
     * @param interfaceID The EIP 165 interface ID.
     * @param implementer The address of a contract that implements this interface for this node.
     */
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) virtual external authorised(node) {
        interfaces[node][interfaceID] = implementer;
        emit InterfaceChanged(node, interfaceID, implementer);
    }

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) virtual override external view returns (address) {
        address implementer = interfaces[node][interfaceID];
        if(implementer != address(0)) {
            return implementer;
        }

        address a = addr(node);
        if(a == address(0)) {
            return address(0);
        }

        (bool success, bytes memory returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", type(ISupportsInterface).interfaceId));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            // EIP 165 not supported by target
            return address(0);
        }

        (success, returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            // Specified interface not supported by target
            return address(0);
        }

        return a;
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IInterfaceResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./INameResolver.sol";

abstract contract NameResolver is INameResolver, ResolverBase {
    mapping(bytes32=>string) names;

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */
    function setName(bytes32 node, string calldata newName) virtual external authorised(node) {
        names[node] = newName;
        emit NameChanged(node, newName);
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) virtual override external view returns (string memory) {
        return names[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(INameResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./IPubkeyResolver.sol";

abstract contract PubkeyResolver is IPubkeyResolver, ResolverBase {
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(bytes32=>PublicKey) pubkeys;

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) virtual external authorised(node) {
        pubkeys[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) virtual override external view returns (bytes32 x, bytes32 y) {
        return (pubkeys[node].x, pubkeys[node].y);
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IPubkeyResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./ITextResolver.sol";

abstract contract TextResolver is ITextResolver, ResolverBase {
    mapping(bytes32=>mapping(string=>string)) texts;

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string calldata key, string calldata value) virtual external authorised(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) virtual override external view returns (string memory) {
        return texts[node][key];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ITextResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMulticallable.sol";
import "./SupportsInterface.sol";

abstract contract Multicallable is IMulticallable, SupportsInterface {
    function multicall(bytes[] calldata data) external override returns(bytes[] memory results) {
        results = new bytes[](data.length);
        for(uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
        return results;
    }

    function supportsInterface(bytes4 interfaceID) public override virtual pure returns(bool) {
        return interfaceID == type(IMulticallable).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SupportsInterface.sol";

abstract contract ResolverBase is SupportsInterface {
    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ISupportsInterface.sol";

abstract contract SupportsInterface is ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ISupportsInterface).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) external pure returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

pragma solidity ^0.8.4;

import "./BytesUtils.sol";
import "@ensdomains/buffer/contracts/Buffer.sol";

/**
* @dev RRUtils is a library that provides utilities for parsing DNS resource records.
*/
library RRUtils {
    using BytesUtils for *;
    using Buffer for *;

    /**
    * @dev Returns the number of bytes in the DNS name at 'offset' in 'self'.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return The length of the DNS name at 'offset', in bytes.
    */
    function nameLength(bytes memory self, uint offset) internal pure returns(uint) {
        uint idx = offset;
        while (true) {
            assert(idx < self.length);
            uint labelLen = self.readUint8(idx);
            idx += labelLen + 1;
            if (labelLen == 0) {
                break;
            }
        }
        return idx - offset;
    }

    /**
    * @dev Returns a DNS format name at the specified offset of self.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return ret The name.
    */
    function readName(bytes memory self, uint offset) internal pure returns(bytes memory ret) {
        uint len = nameLength(self, offset);
        return self.substring(offset, len);
    }

    /**
    * @dev Returns the number of labels in the DNS name at 'offset' in 'self'.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return The number of labels in the DNS name at 'offset', in bytes.
    */
    function labelCount(bytes memory self, uint offset) internal pure returns(uint) {
        uint count = 0;
        while (true) {
            assert(offset < self.length);
            uint labelLen = self.readUint8(offset);
            offset += labelLen + 1;
            if (labelLen == 0) {
                break;
            }
            count += 1;
        }
        return count;
    }

    uint constant RRSIG_TYPE = 0;
    uint constant RRSIG_ALGORITHM = 2;
    uint constant RRSIG_LABELS = 3;
    uint constant RRSIG_TTL = 4;
    uint constant RRSIG_EXPIRATION = 8;
    uint constant RRSIG_INCEPTION = 12;
    uint constant RRSIG_KEY_TAG = 16;
    uint constant RRSIG_SIGNER_NAME = 18;

    struct SignedSet {
        uint16 typeCovered;
        uint8 algorithm;
        uint8 labels;
        uint32 ttl;
        uint32 expiration;
        uint32 inception;
        uint16 keytag;
        bytes signerName;
        bytes data;
        bytes name;
    }

    function readSignedSet(bytes memory data) internal pure returns(SignedSet memory self) {
        self.typeCovered = data.readUint16(RRSIG_TYPE);
        self.algorithm = data.readUint8(RRSIG_ALGORITHM);
        self.labels = data.readUint8(RRSIG_LABELS);
        self.ttl = data.readUint32(RRSIG_TTL);
        self.expiration = data.readUint32(RRSIG_EXPIRATION);
        self.inception = data.readUint32(RRSIG_INCEPTION);
        self.keytag = data.readUint16(RRSIG_KEY_TAG);
        self.signerName = readName(data, RRSIG_SIGNER_NAME);
        self.data = data.substring(RRSIG_SIGNER_NAME + self.signerName.length, data.length - RRSIG_SIGNER_NAME - self.signerName.length);
    }

    function rrs(SignedSet memory rrset) internal pure returns(RRIterator memory) {
        return iterateRRs(rrset.data, 0);
    }

    /**
    * @dev An iterator over resource records.
    */
    struct RRIterator {
        bytes data;
        uint offset;
        uint16 dnstype;
        uint16 class;
        uint32 ttl;
        uint rdataOffset;
        uint nextOffset;
    }

    /**
    * @dev Begins iterating over resource records.
    * @param self The byte string to read from.
    * @param offset The offset to start reading at.
    * @return ret An iterator object.
    */
    function iterateRRs(bytes memory self, uint offset) internal pure returns (RRIterator memory ret) {
        ret.data = self;
        ret.nextOffset = offset;
        next(ret);
    }

    /**
    * @dev Returns true iff there are more RRs to iterate.
    * @param iter The iterator to check.
    * @return True iff the iterator has finished.
    */
    function done(RRIterator memory iter) internal pure returns(bool) {
        return iter.offset >= iter.data.length;
    }

    /**
    * @dev Moves the iterator to the next resource record.
    * @param iter The iterator to advance.
    */
    function next(RRIterator memory iter) internal pure {
        iter.offset = iter.nextOffset;
        if (iter.offset >= iter.data.length) {
            return;
        }

        // Skip the name
        uint off = iter.offset + nameLength(iter.data, iter.offset);

        // Read type, class, and ttl
        iter.dnstype = iter.data.readUint16(off);
        off += 2;
        iter.class = iter.data.readUint16(off);
        off += 2;
        iter.ttl = iter.data.readUint32(off);
        off += 4;

        // Read the rdata
        uint rdataLength = iter.data.readUint16(off);
        off += 2;
        iter.rdataOffset = off;
        iter.nextOffset = off + rdataLength;
    }

    /**
    * @dev Returns the name of the current record.
    * @param iter The iterator.
    * @return A new bytes object containing the owner name from the RR.
    */
    function name(RRIterator memory iter) internal pure returns(bytes memory) {
        return iter.data.substring(iter.offset, nameLength(iter.data, iter.offset));
    }

    /**
    * @dev Returns the rdata portion of the current record.
    * @param iter The iterator.
    * @return A new bytes object containing the RR's RDATA.
    */
    function rdata(RRIterator memory iter) internal pure returns(bytes memory) {
        return iter.data.substring(iter.rdataOffset, iter.nextOffset - iter.rdataOffset);
    }

    uint constant DNSKEY_FLAGS = 0;
    uint constant DNSKEY_PROTOCOL = 2;
    uint constant DNSKEY_ALGORITHM = 3;
    uint constant DNSKEY_PUBKEY = 4;

    struct DNSKEY {
        uint16 flags;
        uint8 protocol;
        uint8 algorithm;
        bytes publicKey;
    }

    function readDNSKEY(bytes memory data, uint offset, uint length) internal pure returns(DNSKEY memory self) {
        self.flags = data.readUint16(offset + DNSKEY_FLAGS);
        self.protocol = data.readUint8(offset + DNSKEY_PROTOCOL);
        self.algorithm = data.readUint8(offset + DNSKEY_ALGORITHM);
        self.publicKey = data.substring(offset + DNSKEY_PUBKEY, length - DNSKEY_PUBKEY);
    } 

    uint constant DS_KEY_TAG = 0;
    uint constant DS_ALGORITHM = 2;
    uint constant DS_DIGEST_TYPE = 3;
    uint constant DS_DIGEST = 4;

    struct DS {
        uint16 keytag;
        uint8 algorithm;
        uint8 digestType;
        bytes digest;
    }

    function readDS(bytes memory data, uint offset, uint length) internal pure returns(DS memory self) {
        self.keytag = data.readUint16(offset + DS_KEY_TAG);
        self.algorithm = data.readUint8(offset + DS_ALGORITHM);
        self.digestType = data.readUint8(offset + DS_DIGEST_TYPE);
        self.digest = data.substring(offset + DS_DIGEST, length - DS_DIGEST);
    }

    struct NSEC3 {
        uint8 hashAlgorithm;
        uint8 flags;
        uint16 iterations;
        bytes salt;
        bytes32 nextHashedOwnerName;
        bytes typeBitmap;
    }

    uint constant NSEC3_HASH_ALGORITHM = 0;
    uint constant NSEC3_FLAGS = 1;
    uint constant NSEC3_ITERATIONS = 2;
    uint constant NSEC3_SALT_LENGTH = 4;
    uint constant NSEC3_SALT = 5;

    function readNSEC3(bytes memory data, uint offset, uint length) internal pure returns(NSEC3 memory self) {
        uint end = offset + length;
        self.hashAlgorithm = data.readUint8(offset + NSEC3_HASH_ALGORITHM);
        self.flags = data.readUint8(offset + NSEC3_FLAGS);
        self.iterations = data.readUint16(offset + NSEC3_ITERATIONS);
        uint8 saltLength = data.readUint8(offset + NSEC3_SALT_LENGTH);
        offset = offset + NSEC3_SALT;
        self.salt = data.substring(offset, saltLength);
        offset += saltLength;
        uint8 nextLength = data.readUint8(offset);
        require(nextLength <= 32);
        offset += 1;
        self.nextHashedOwnerName = data.readBytesN(offset, nextLength);
        offset += nextLength;
        self.typeBitmap = data.substring(offset, end - offset);
    }

    function checkTypeBitmap(NSEC3 memory self, uint16 rrtype) internal pure returns(bool) {
        return checkTypeBitmap(self.typeBitmap, 0, rrtype);
    }

    /**
    * @dev Checks if a given RR type exists in a type bitmap.
    * @param bitmap The byte string to read the type bitmap from.
    * @param offset The offset to start reading at.
    * @param rrtype The RR type to check for.
    * @return True if the type is found in the bitmap, false otherwise.
    */
    function checkTypeBitmap(bytes memory bitmap, uint offset, uint16 rrtype) internal pure returns (bool) {
        uint8 typeWindow = uint8(rrtype >> 8);
        uint8 windowByte = uint8((rrtype & 0xff) / 8);
        uint8 windowBitmask = uint8(uint8(1) << (uint8(7) - uint8(rrtype & 0x7)));
        for (uint off = offset; off < bitmap.length;) {
            uint8 window = bitmap.readUint8(off);
            uint8 len = bitmap.readUint8(off + 1);
            if (typeWindow < window) {
                // We've gone past our window; it's not here.
                return false;
            } else if (typeWindow == window) {
                // Check this type bitmap
                if (len <= windowByte) {
                    // Our type is past the end of the bitmap
                    return false;
                }
                return (bitmap.readUint8(off + windowByte + 2) & windowBitmask) != 0;
            } else {
                // Skip this type bitmap
                off += len + 2;
            }
        }

        return false;
    }

    function compareNames(bytes memory self, bytes memory other) internal pure returns (int) {
        if (self.equals(other)) {
            return 0;
        }

        uint off;
        uint otheroff;
        uint prevoff;
        uint otherprevoff;
        uint counts = labelCount(self, 0);
        uint othercounts = labelCount(other, 0);

        // Keep removing labels from the front of the name until both names are equal length
        while (counts > othercounts) {
            prevoff = off;
            off = progress(self, off);
            counts--;
        }

        while (othercounts > counts) {
            otherprevoff = otheroff;
            otheroff = progress(other, otheroff);
            othercounts--;
        }

        // Compare the last nonequal labels to each other
        while (counts > 0 && !self.equals(off, other, otheroff)) {
            prevoff = off;
            off = progress(self, off);
            otherprevoff = otheroff;
            otheroff = progress(other, otheroff);
            counts -= 1;
        }

        if (off == 0) {
            return -1;
        }
        if(otheroff == 0) {
            return 1;
        }

        return self.compare(prevoff + 1, self.readUint8(prevoff), other, otherprevoff + 1, other.readUint8(otherprevoff));
    }

    /**
     * @dev Compares two serial numbers using RFC1982 serial number math.
     */
    function serialNumberGte(uint32 i1, uint32 i2) internal pure returns(bool) {
        return int32(i1) - int32(i2) >= 0;
    }

    function progress(bytes memory body, uint off) internal pure returns(uint) {
        return off + 1 + body.readUint8(off);
    }

    /**
     * @dev Computes the keytag for a chunk of data.
     * @param data The data to compute a keytag for.
     * @return The computed key tag.
     */
    function computeKeytag(bytes memory data) internal pure returns (uint16) {
        /* This function probably deserves some explanation.
         * The DNSSEC keytag function is a checksum that relies on summing up individual bytes
         * from the input string, with some mild bitshifting. Here's a Naive solidity implementation:
         *
         *     function computeKeytag(bytes memory data) internal pure returns (uint16) {
         *         uint ac;
         *         for (uint i = 0; i < data.length; i++) {
         *             ac += i & 1 == 0 ? uint16(data.readUint8(i)) << 8 : data.readUint8(i);
         *         }
         *         return uint16(ac + (ac >> 16));
         *     }
         *
         * The EVM, with its 256 bit words, is exceedingly inefficient at doing byte-by-byte operations;
         * the code above, on reasonable length inputs, consumes over 100k gas. But we can make the EVM's
         * large words work in our favour.
         *
         * The code below works by treating the input as a series of 256 bit words. It first masks out
         * even and odd bytes from each input word, adding them to two separate accumulators `ac1` and `ac2`.
         * The bytes are separated by empty bytes, so as long as no individual sum exceeds 2^16-1, we're
         * effectively summing 16 different numbers with each EVM ADD opcode.
         *
         * Once it's added up all the inputs, it has to add all the 16 bit values in `ac1` and `ac2` together.
         * It does this using the same trick - mask out every other value, shift to align them, add them together.
         * After the first addition on both accumulators, there's enough room to add the two accumulators together,
         * and the remaining sums can be done just on ac1.
         */
        unchecked {
            require(data.length <= 8192, "Long keys not permitted");
            uint ac1;
            uint ac2;
            for(uint i = 0; i < data.length + 31; i += 32) {
                uint word;
                assembly {
                    word := mload(add(add(data, 32), i))
                }
                if(i + 32 > data.length) {
                    uint unused = 256 - (data.length - i) * 8;
                    word = (word >> unused) << unused;
                }
                ac1 += (word & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8;
                ac2 += (word & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF);
            }
            ac1 = (ac1 & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF)
                + ((ac1 & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16);
            ac2 = (ac2 & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF)
                + ((ac2 & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16);
            ac1 = (ac1 << 8) + ac2;
            ac1 = (ac1 & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF)
                + ((ac1 & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32);
            ac1 = (ac1 & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF)
                + ((ac1 & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64);
            ac1 = (ac1 & 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                + (ac1 >> 128);
            ac1 += (ac1 >> 16) & 0xFFFF;
            return uint16(ac1);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSRecordResolver {
    // DNSRecordChanged is emitted whenever a given node/name/resource's RRSET is updated.
    event DNSRecordChanged(bytes32 indexed node, bytes name, uint16 resource, bytes record);
    // DNSRecordDeleted is emitted whenever a given node/name/resource's RRSET is deleted.
    event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);
    // DNSZoneCleared is emitted whenever a given node's zone information is cleared.
    event DNSZoneCleared(bytes32 indexed node);

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSZoneResolver {
    // DNSZonehashChanged is emitted whenever a given node's zone hash is updated.
    event DNSZonehashChanged(bytes32 indexed node, bytes lastzonehash, bytes zonehash);

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) external view returns (bytes memory);
}

pragma solidity ^0.8.4;

library BytesUtils {
    /*
    * @dev Returns the keccak-256 hash of a byte range.
    * @param self The byte string to hash.
    * @param offset The position to start hashing at.
    * @param len The number of bytes to hash.
    * @return The hash of the byte range.
    */
    function keccak(bytes memory self, uint offset, uint len) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }


    /*
    * @dev Returns a positive number if `other` comes lexicographically after
    *      `self`, a negative number if it comes before, or zero if the
    *      contents of the two bytes are equal.
    * @param self The first bytes to compare.
    * @param other The second bytes to compare.
    * @return The result of the comparison.
    */
    function compare(bytes memory self, bytes memory other) internal pure returns (int) {
        return compare(self, 0, self.length, other, 0, other.length);
    }

    /*
    * @dev Returns a positive number if `other` comes lexicographically after
    *      `self`, a negative number if it comes before, or zero if the
    *      contents of the two bytes are equal. Comparison is done per-rune,
    *      on unicode codepoints.
    * @param self The first bytes to compare.
    * @param offset The offset of self.
    * @param len    The length of self.
    * @param other The second bytes to compare.
    * @param otheroffset The offset of the other string.
    * @param otherlen    The length of the other string.
    * @return The result of the comparison.
    */
    function compare(bytes memory self, uint offset, uint len, bytes memory other, uint otheroffset, uint otherlen) internal pure returns (int) {
        uint shortest = len;
        if (otherlen < len)
        shortest = otherlen;

        uint selfptr;
        uint otherptr;

        assembly {
            selfptr := add(self, add(offset, 32))
            otherptr := add(other, add(otheroffset, 32))
        }
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask;
                if (shortest > 32) {
                    mask = type(uint256).max;
                } else {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                int diff = int(a & mask) - int(b & mask);
                if (diff != 0)
                return diff;
            }
            selfptr += 32;
            otherptr += 32;
        }

        return int(len) - int(otherlen);
    }

    /*
    * @dev Returns true if the two byte ranges are equal.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @param otherOffset The offset into the second byte range.
    * @param len The number of bytes to compare
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other, uint otherOffset, uint len) internal pure returns (bool) {
        return keccak(self, offset, len) == keccak(other, otherOffset, len);
    }

    /*
    * @dev Returns true if the two byte ranges are equal with offsets.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @param otherOffset The offset into the second byte range.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other, uint otherOffset) internal pure returns (bool) {
        return keccak(self, offset, self.length - offset) == keccak(other, otherOffset, other.length - otherOffset);
    }

    /*
    * @dev Compares a range of 'self' to all of 'other' and returns True iff
    *      they are equal.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other) internal pure returns (bool) {
        return self.length >= offset + other.length && equals(self, offset, other, 0, other.length);
    }

    /*
    * @dev Returns true if the two byte ranges are equal.
    * @param self The first byte range to compare.
    * @param other The second byte range to compare.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, bytes memory other) internal pure returns(bool) {
        return self.length == other.length && equals(self, 0, other, 0, self.length);
    }

    /*
    * @dev Returns the 8-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 8 bits of the string, interpreted as an integer.
    */
    function readUint8(bytes memory self, uint idx) internal pure returns (uint8 ret) {
        return uint8(self[idx]);
    }

    /*
    * @dev Returns the 16-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 16 bits of the string, interpreted as an integer.
    */
    function readUint16(bytes memory self, uint idx) internal pure returns (uint16 ret) {
        require(idx + 2 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 2), idx)), 0xFFFF)
        }
    }

    /*
    * @dev Returns the 32-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bits of the string, interpreted as an integer.
    */
    function readUint32(bytes memory self, uint idx) internal pure returns (uint32 ret) {
        require(idx + 4 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 4), idx)), 0xFFFFFFFF)
        }
    }

    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes32(bytes memory self, uint idx) internal pure returns (bytes32 ret) {
        require(idx + 32 <= self.length);
        assembly {
            ret := mload(add(add(self, 32), idx))
        }
    }

    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes20(bytes memory self, uint idx) internal pure returns (bytes20 ret) {
        require(idx + 20 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 32), idx)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000)
        }
    }

    /*
    * @dev Returns the n byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes.
    * @param len The number of bytes.
    * @return The specified 32 bytes of the string.
    */
    function readBytesN(bytes memory self, uint idx, uint len) internal pure returns (bytes32 ret) {
        require(len <= 32);
        require(idx + len <= self.length);
        assembly {
            let mask := not(sub(exp(256, sub(32, len)), 1))
            ret := and(mload(add(add(self, 32), idx)),  mask)
        }
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }
    }

    /*
    * @dev Copies a substring into a new byte string.
    * @param self The byte string to copy from.
    * @param offset The offset to start copying at.
    * @param len The number of bytes to copy.
    */
    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        require(offset + len <= self.length);

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        assembly {
            dest := add(ret, 32)
            src := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }

    // Maps characters from 0x30 to 0x7A to their base32 values.
    // 0xFF represents invalid characters in that range.
    bytes constant base32HexTable = hex'00010203040506070809FFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1FFFFFFFFFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1F';

    /**
     * @dev Decodes unpadded base32 data of up to one word in length.
     * @param self The data to decode.
     * @param off Offset into the string to start at.
     * @param len Number of characters to decode.
     * @return The decoded data, left aligned.
     */
    function base32HexDecodeWord(bytes memory self, uint off, uint len) internal pure returns(bytes32) {
        require(len <= 52);

        uint ret = 0;
        uint8 decoded;
        for(uint i = 0; i < len; i++) {
            bytes1 char = self[off + i];
            require(char >= 0x30 && char <= 0x7A);
            decoded = uint8(base32HexTable[uint(uint8(char)) - 0x30]);
            require(decoded <= 0x20);
            if(i == len - 1) {
                break;
            }
            ret = (ret << 5) | decoded;
        }

        uint bitlen = len * 5;
        if(len % 8 == 0) {
            // Multiple of 8 characters, no padding
            ret = (ret << 5) | decoded;
        } else if(len % 8 == 2) {
            // Two extra characters - 1 byte
            ret = (ret << 3) | (decoded >> 2);
            bitlen -= 2;
        } else if(len % 8 == 4) {
            // Four extra characters - 2 bytes
            ret = (ret << 1) | (decoded >> 4);
            bitlen -= 4;
        } else if(len % 8 == 5) {
            // Five extra characters - 3 bytes
            ret = (ret << 4) | (decoded >> 1);
            bitlen -= 1;
        } else if(len % 8 == 7) {
            // Seven extra characters - 4 bytes
            ret = (ret << 2) | (decoded >> 3);
            bitlen -= 3;
        } else {
            revert();
        }

        return bytes32(ret << (256 - bitlen));
    }
}

pragma solidity ^0.8.4;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library Buffer {
    /**
    * @dev Represents a mutable buffer. Buffers have a current value (buf) and
    *      a capacity. The capacity may be longer than the current value, in
    *      which case it can be extended without the need to allocate more memory.
    */
    struct buffer {
        bytes buf;
        uint capacity;
    }

    /**
    * @dev Initializes a buffer with an initial capacity.
    * @param buf The buffer to initialize.
    * @param capacity The number of bytes of space to allocate the buffer.
    * @return The buffer, for chaining.
    */
    function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    /**
    * @dev Initializes a new buffer from an existing bytes object.
    *      Changes to the buffer may mutate the original value.
    * @param b The bytes object to initialize the buffer with.
    * @return A new buffer.
    */
    function fromBytes(bytes memory b) internal pure returns(buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns(uint) {
        if (a > b) {
            return a;
        }
        return b;
    }

    /**
    * @dev Sets buffer length to 0.
    * @param buf The buffer to truncate.
    * @return The original buffer, for chaining..
    */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
    * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The start offset to write to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns(buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint dest;
        uint src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        return buf;
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    /**
    * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write the byte at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
        if (off >= buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if eq(off, buflen) {
                mstore(bufptr, add(buflen, 1))
            }
        }
        return buf;
    }

    /**
    * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    /**
    * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
    *      exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (left-aligned).
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns(buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        unchecked {
            uint mask = (256 ** len) - 1;
            // Right-align data
            data = data >> (8 * (32 - len));
            assembly {
                // Memory address of the buffer data
                let bufptr := mload(buf)
                // Address = buffer address + sizeof(buffer length) + off + len
                let dest := add(add(bufptr, off), len)
                mstore(dest, or(and(mload(dest), not(mask)), data))
                // Update buffer length if we extended it
                if gt(add(off, len), mload(bufptr)) {
                    mstore(bufptr, add(off, len))
                }
            }
        }
        return buf;
    }

    /**
    * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, off, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chhaining.
    */
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, 32);
    }

    /**
    * @dev Writes an integer to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (right-aligned).
    * @return The original buffer, for chaining.
    */
    function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns(buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint mask = (256 ** len) - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + off + sizeof(buffer length) + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IInterfaceResolver {
    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMulticallable {
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
}