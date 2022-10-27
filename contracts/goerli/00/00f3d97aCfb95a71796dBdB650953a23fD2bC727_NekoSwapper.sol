pragma solidity 0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";

interface INekoNation {
    function MAX_SUPPLY() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function devMint(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract NekoSwapper is Ownable {
    /* TODO CHANGE TO MAINNET ADDRESS */
    address public NekonationContractAddress =
        0xcB190289aAd7D2941F109643C124D9cddF1f4E1D;

    INekoNation NekonationContract = INekoNation(NekonationContractAddress);
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    uint256 public swapTimeThreshold = 69 minutes;
    uint256 public swapFee = 0 ether;
    mapping(uint256 => uint256) public lastSwapTimeOfTokenId;

    function changeSwapFee(uint256 newSwapFee) external onlyOwner {
        swapFee = newSwapFee;
    }

    function changeSwapTimeThreshold(uint256 newSwapTimeThreshold)
        external
        onlyOwner
    {
        swapTimeThreshold = newSwapTimeThreshold;
    }

    function contractHasSupportRole() public view returns (bool) {
        return NekonationContract.hasRole(SUPPORT_ROLE, address(this));
    }

    function contractHasApproval() public view returns (bool) {
        return NekonationContract.isApprovedForAll(msg.sender, address(this));
    }

    function getTokenIDsTimes(uint256[] memory usersTokenIDsArray)
        external
        view
        returns (uint256[] memory)
    {
        uint256 resLength = usersTokenIDsArray.length;
        uint256[] memory tokenIDsTimes = new uint256[](resLength);
        for (uint256 i = 0; i < resLength; i++) {
            tokenIDsTimes[i] = lastSwapTimeOfTokenId[usersTokenIDsArray[i]];
        }
        return tokenIDsTimes;
    }

    /* not needed because i can access the API directly 
    function getTokenURI(uint256 id) external view returns (string memory) {
        return NekonationContract.tokenURI(id);
    } */

    /// @notice Swaps old NekoNation NFT for new one until supply max is reached
    /// @dev requires SUPPORT role granted to contract address,
    ///      requires Approval of msg.sender to transfer his token
    ///      this SC holds the transfered old Token, since burning is not possible
    /// @param oldTokenIds array of tokenIds that you want to swap for new ones
    function swap(uint256[] memory oldTokenIds) external payable {
        // contract checks
        require(contractHasApproval(), "approval to contract missing");
        require(
            NekonationContract.hasRole(SUPPORT_ROLE, address(this)),
            "Support Role to contract missing"
        );

        require(
            tokenIDsOwnershipValid(oldTokenIds),
            "msg.sender not owner of all oldTokenIds"
        );

        // amount check
        uint256 tokenAmount = oldTokenIds.length;
        require(
            tokenAmount > 0 && tokenAmount <= 20,
            "incorrect amount of oldTokenIds"
        );

        require(tokenIDsTimeCanSwap(oldTokenIds), "tokenId cannot swap yet");
        // check correct payment
        require(msg.value >= swapFee * tokenAmount, "price not paid");

        uint256 currentSupply = NekonationContract.totalSupply();
        // check if tokenAmount exceeds MAX_SUPPLY
        require(
            currentSupply + tokenAmount < NekonationContract.MAX_SUPPLY(),
            "maxSupply reached"
        );
        // send old tokens to contract
        for (uint256 i = 0; i < oldTokenIds.length; i++) {
            NekonationContract.transferFrom(
                msg.sender,
                address(this),
                oldTokenIds[i]
            );
            // block swap for the new tokens
            uint256 futureTokenId = currentSupply + i;
            lastSwapTimeOfTokenId[futureTokenId] = block.timestamp;
        }

        NekonationContract.devMint(msg.sender, tokenAmount);
    }

    function testMAX_SUPPLY() external view returns (uint256) {
        return NekonationContract.MAX_SUPPLY();
    }

    function tokenIDsOwnershipValid(uint256[] memory tokenIds)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (NekonationContract.ownerOf(tokenIds[i]) != msg.sender) {
                return false;
            }
        }
        return true;
    }

    function tokenIDsTimeCanSwap(uint256[] memory tokenIds)
        public
        view
        returns (bool)
    {
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                lastSwapTimeOfTokenId[tokenIds[i]] + swapTimeThreshold >
                currentTime
            ) {
                return false;
            }
        }
        return true;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = NekonationContract.balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        uint256 maxSupply = NekonationContract.totalSupply();
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = NekonationContract.ownerOf(
                currentTokenId
            );
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "tx failed");
    }
}
// by SRB

/* function swap(uint256 oldTokenId) external payable {
        require(contractHasApproval(), "approval to contract missing");

        require(
            NekonationContract.hasRole(SUPPORT_ROLE, address(this)),
            "Support Role to contract missing"
        );

        require(
            NekonationContract.ownerOf(oldTokenId) == msg.sender,
            "msg.sender not owner of tokenID"
        );

        require(tokenIdCanSwapAgain(oldTokenId), "tokenId cannot swap yet");
        require(msg.value >= swapFee, "price not paid");

        NekonationContract.transferFrom(msg.sender, address(this), oldTokenId);
        uint256 nextTokenId = NekonationContract.totalSupply();
        lastSwapTimeOfTokenId[nextTokenId] = block.timestamp;
        NekonationContract.devMint(msg.sender, 1);
    } */

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