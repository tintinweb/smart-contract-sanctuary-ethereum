//SPDX-License-Identifier: MIT

// principles: minimize memory storage, breakdown a complex on-chain action to several short actions
// Must functions: connectWallet, showLoanableNFT, setBasePrice(real fp deal in 14days), setThreshold(e.g., 60%on base price),
//                 autoGenOffers(3 offers: amount[100,80,60], period[3,7,14], APR[80,100,120], +some random disturbation),
//                 manGenOffers(amount, period, APR, ),
//                 updateOffers(offerIndex, update=0:del/1:update/2)
//                 acceptOffer(approveTransfer, nftDeposit,loanTransfer)
// Later functions: getPrice, showOffers, makeOffers, approve,sendOffers
// Struct: offer{evalAmount, loanPeriod, interest}
// Global array: arrPeriod[3,7,14], arrAPR, arrLoanRatio
// randome value: randDeltaAPR,randDeltaLoanRatio

// ? how to get rarity info. then corresponding evalPrice -> metadata
// ? how to achieve bundle or reduce gas fee
//
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC721.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract Escrow is Ownable {
    address[] public allowedNfts;
    uint256 public numOfAllowedNfts;
    mapping(address => address) public nftPriceFeedMapping; // need to upgraded to ranks

    IERC20 public dappToken;

    uint256 public interestDecimals = 4;

    // mapping borrower address -> borrower stake index -> staked NFT address and ID
    mapping(address => mapping(uint256 => address)) public stakedNftAddress;
    mapping(address => mapping(uint256 => uint256)) public stakedNftId;
    // mapping borrower address -> nft address -> nft ID -> staked index
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public stakedNftIndex;
    mapping(address => uint256) public numOfNftStaked;
    address[] public borrowers;
    uint256 public numOfBorrowers;
    mapping(address => uint256) public borrowerIndex;
    // mapping nft address -> nft id -> { expireTime, repayAmount, holderAddress}
    mapping(address => mapping(uint256 => uint256)) public nftLoanRepayAmount;
    mapping(address => mapping(uint256 => uint256)) public nftLoanExpireTime;
    mapping(address => mapping(uint256 => address)) public nftLoanHolderAddress;
    // mapping nft address -> nft id -> { loanPeriod, loanAmount, loanInterest}
    mapping(address => mapping(uint256 => uint256)) public nftLoanAmount; // unit: wei
    mapping(address => mapping(uint256 => uint256)) public nftLoanPeriod; // unit: days
    mapping(address => mapping(uint256 => uint256)) public nftLoanInterest; // decimals: 4
    // mapping nft address -> { loanPeriod, loanAmount, loanInterest} collection offer
    mapping(address => uint256) nftCollectionLoanAmount; // unit: wei
    mapping(address => uint256) nftCollectionLoanPeriod; // unit: days
    mapping(address => uint256) nftCollectionLoanInterest; // decimals: 4

    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
        numOfAllowedNfts = 0;
    }

    function loanRepay(address _loanTokenAddress, uint256 _repayAmount)
        internal
    {
        // where shall we put approve action, here or in .py?
        IERC20(_loanTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _repayAmount
        );
    }

    function loanTransfer(
        address _loanTokenAddress,
        address _nftHolderAddress,
        uint256 _loanAmount
    ) internal {
        // is onlyOwner used here correct?
        IERC20(_loanTokenAddress).transfer(_nftHolderAddress, _loanAmount);
    }

    function loanMTransfer(
        address _loanTokenAddress,
        address _nftHolderAddress,
        uint256 _loanAmount
    ) public onlyOwner {
        // is onlyOwner used here correct?
        IERC20(_loanTokenAddress).transfer(_nftHolderAddress, _loanAmount);
    }

    function requestLoan(
        address _loanTokenAddress,
        address _nftAddress,
        uint256 _nftId
    ) public {
        require(
            nftIsAllowed(_nftAddress),
            "current nft is not allowed in our whitelist!"
        );

        (
            uint256 _loanAmount,
            uint256 _loanDays,
            uint256 _loanInterest
        ) = getOffers(_nftAddress, _nftId); //???should change _loanAmount to ??????
        require(
            IERC20(_loanTokenAddress).balanceOf(address(this)) >= _loanAmount,
            "Current lender has not sufficient fund, please contact our staff~"
        );
        nftStaking(_nftAddress, _nftId);
        loanTransfer(_loanTokenAddress, address(msg.sender), _loanAmount);
        // IERC20(_loanTokenAddress).transfer(address(msg.sender), _loanAmount);
        uint256 initTime = block.timestamp;
        uint256 expireTime = initTime + _loanDays * 24 * 60 * 60;
        uint256 repayAmount = (_loanAmount *
            (1 * (10**interestDecimals) + _loanInterest)) /
            (10**interestDecimals);
        nftLock(
            _nftAddress,
            _nftId,
            address(msg.sender),
            expireTime,
            repayAmount
        );
    }

    function redeemLoan(
        address _loanTokenAddress,
        address _nftAddress,
        uint256 _nftId
    ) public {
        require(
            nftIsAllowed(_nftAddress),
            "current nft is not allowed in our whitelist!"
        );

        (
            address holder_address,
            uint256 expire_time,
            uint256 repay_amount
        ) = getNftLockData(_nftAddress, _nftId);
        uint256 currentTime = block.timestamp;
        require(
            holder_address == msg.sender,
            "please use correct wallet to repay and unstake!"
        );
        require(
            currentTime < expire_time,
            "your loan is overdue, please contact our staff to find solution!"
        );
        require(
            IERC20(_loanTokenAddress).balanceOf(msg.sender) >= repay_amount,
            "your balance is not enough to replay the loan!"
        );
        loanRepay(_loanTokenAddress, repay_amount);
        nftUnStaking(_nftAddress, _nftId);
    }

    function nftStaking(address _nftAddress, uint256 _nftId) internal {
        require(
            nftIsAllowed(_nftAddress),
            "current nft is not allowed in our whitelist!"
        );
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _nftId);
        stakedNftAddress[msg.sender][numOfNftStaked[msg.sender]] = _nftAddress;
        stakedNftId[msg.sender][numOfNftStaked[msg.sender]] = _nftId;
        stakedNftIndex[msg.sender][_nftAddress][_nftId] = numOfNftStaked[
            msg.sender
        ];
        if (numOfNftStaked[msg.sender] == 0) {
            borrowers.push(msg.sender);
            borrowerIndex[msg.sender] = borrowers.length - 1;
            numOfBorrowers = numOfBorrowers + 1;
        }
        numOfNftStaked[msg.sender] = numOfNftStaked[msg.sender] + 1;
    }

    function nftUnStaking(address _nftAddress, uint256 _nftId) internal {
        require(
            nftIsAllowed(_nftAddress),
            "current nft is not allowed in our whitelist!"
        );

        IERC721(_nftAddress).transferFrom(address(this), msg.sender, _nftId);
        uint256 index = stakedNftIndex[msg.sender][_nftAddress][_nftId];
        address nft_address = stakedNftAddress[msg.sender][
            numOfNftStaked[msg.sender] - 1
        ];
        uint256 nft_id = stakedNftId[msg.sender][
            numOfNftStaked[msg.sender] - 1
        ];
        stakedNftAddress[msg.sender][index] = nft_address;
        stakedNftId[msg.sender][index] = nft_id;
        stakedNftIndex[msg.sender][nft_address][nft_id] = index;
        numOfNftStaked[msg.sender] = numOfNftStaked[msg.sender] - 1;

        if (numOfNftStaked[msg.sender] == 0) {
            index = borrowerIndex[msg.sender];
            borrowers[index] = borrowers[borrowers.length - 1];
            borrowerIndex[borrowers[index]] = index;
            borrowers.pop();
            numOfBorrowers = numOfBorrowers - 1;
        }
    }

    function nftMUnStaking(address _nftAddress, uint256 _nftId)
        public
        onlyOwner
    {
        // must satisfy:
        // 1. time not expire,
        // 2. repay enough,
        // 3. the owner is the owner
        require(
            nftIsAllowed(_nftAddress),
            "current nft is not allowed in our whitelist!"
        );

        IERC721(_nftAddress).transferFrom(address(this), msg.sender, _nftId);
        uint256 index = stakedNftIndex[msg.sender][_nftAddress][_nftId];
        address nft_address = stakedNftAddress[msg.sender][
            numOfNftStaked[msg.sender] - 1
        ];
        uint256 nft_id = stakedNftId[msg.sender][
            numOfNftStaked[msg.sender] - 1
        ];
        stakedNftAddress[msg.sender][index] = nft_address;
        stakedNftId[msg.sender][index] = nft_id;
        stakedNftIndex[msg.sender][nft_address][nft_id] = index;
        numOfNftStaked[msg.sender] = numOfNftStaked[msg.sender] - 1;

        if (numOfNftStaked[msg.sender] == 0) {
            index = borrowerIndex[msg.sender];
            borrowers[index] = borrowers[borrowers.length - 1];
            borrowerIndex[borrowers[index]] = index;
            borrowers.pop();
            numOfBorrowers = numOfBorrowers - 1;
        }
    }

    function setOffers(
        address _nftAddress,
        uint256 _nftId,
        uint256 _loanAmount,
        uint256 _loanPeriod,
        uint256 _loanInterest
    ) public onlyOwner {
        nftLoanAmount[_nftAddress][_nftId] = _loanAmount;
        nftLoanInterest[_nftAddress][_nftId] = _loanInterest;
        nftLoanPeriod[_nftAddress][_nftId] = _loanPeriod;
    }

    function setCollectionOffers(
        address _nftAddress,
        uint256 _loanAmount,
        uint256 _loanPeriod,
        uint256 _loanInterest
    ) public onlyOwner {
        nftCollectionLoanAmount[_nftAddress] = _loanAmount;
        nftCollectionLoanInterest[_nftAddress] = _loanInterest;
        nftCollectionLoanPeriod[_nftAddress] = _loanPeriod;
    }

    function getOffers(address _nftAddress, uint256 _nftId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 loan_amount = nftLoanAmount[_nftAddress][_nftId];
        uint256 loan_interest = nftLoanInterest[_nftAddress][_nftId];
        uint256 loan_period = nftLoanPeriod[_nftAddress][_nftId];
        return (loan_amount, loan_period, loan_interest);
    }

    function nftLock(
        address _nftAddress,
        uint256 _nftId,
        address _holderAddress,
        uint256 _expireTime,
        uint256 _repayAmount
    ) internal {
        // nft lock parameters setting, is the function public ok?
        nftLoanHolderAddress[_nftAddress][_nftId] = _holderAddress;
        nftLoanExpireTime[_nftAddress][_nftId] = _expireTime;
        nftLoanRepayAmount[_nftAddress][_nftId] = _repayAmount;
    }

    function nftMLock(
        address _nftAddress,
        uint256 _nftId,
        address _holderAddress,
        uint256 _expireTime,
        uint256 _repayAmount
    ) public onlyOwner {
        // nft lock parameters setting, is the function public ok?
        nftLoanHolderAddress[_nftAddress][_nftId] = _holderAddress;
        nftLoanExpireTime[_nftAddress][_nftId] = _expireTime;
        nftLoanRepayAmount[_nftAddress][_nftId] = _repayAmount;
    }

    function getNftLockData(address _nftAddress, uint256 _nftId)
        internal
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        return (
            nftLoanHolderAddress[_nftAddress][_nftId],
            nftLoanExpireTime[_nftAddress][_nftId],
            nftLoanRepayAmount[_nftAddress][_nftId]
        );
    }

    function addAllowedNfts(address _nftAddress)
        internal
        onlyOwner
        returns (bool)
    {
        for (
            uint256 allowedNftsIndex = 0;
            allowedNftsIndex < allowedNfts.length;
            allowedNftsIndex++
        ) {
            if (allowedNfts[allowedNftsIndex] == _nftAddress) {
                return false;
            }
        }
        allowedNfts.push(_nftAddress);
        numOfAllowedNfts = numOfAllowedNfts + 1;
        return true;
    }

    function delAllowedNfts(address _nftAddress)
        internal
        onlyOwner
        returns (bool)
    {
        for (
            uint256 allowedNftsIndex = 0;
            allowedNftsIndex < allowedNfts.length;
            allowedNftsIndex++
        ) {
            if (allowedNfts[allowedNftsIndex] == _nftAddress) {
                allowedNfts[allowedNftsIndex] = allowedNfts[
                    allowedNfts.length - 1
                ];
                allowedNfts.pop();
                numOfAllowedNfts = numOfAllowedNfts - 1;
                return true;
            }
        }
        return false;
    }

    function updateAllowedNfts(address _nftAddress, bool _update)
        public
        onlyOwner
        returns (bool)
    {
        if (_update == true) {
            return addAllowedNfts(_nftAddress);
        } else {
            return delAllowedNfts(_nftAddress);
        }
    }

    function nftIsAllowed(address _nftAddress) public view returns (bool) {
        for (
            uint256 allowedNftsIndex = 0;
            allowedNftsIndex < allowedNfts.length;
            allowedNftsIndex++
        ) {
            if (allowedNfts[allowedNftsIndex] == _nftAddress) {
                return true;
            }
        }
        return false;
    }

    // function getAllowedNfts() public view returns(address []){}

    function isBorrowers(address _user) public view returns (bool) {
        for (uint256 index = 0; index < allowedNfts.length; index++) {
            if (borrowers[index] == _user) {
                return true;
            }
        }
        return false;
    }

    modifier onlyBorrower() {
        require(isBorrowers(msg.sender), "Only borrower can call this method");
        _;
    }

    function setPriceFeedContract(
        address _nftAddress,
        // uint256 _nftId=none,
        address _priceFeed
    ) public onlyOwner {
        // nftPriceFeedMapping[_nftAddress][_nftId] = _priceFeed;
        nftPriceFeedMapping[_nftAddress] = _priceFeed;
    }

    // function getBalance() public view returns (uint256) {
    //     return address(this).balance;
    // }

    // // e.g.: give 1 DappToken per loanToken loan
    // function issueTokens() public onlyOwner {
    //     // ? get each borrower total loan interest profit
    //     // ? get each NFT (address, id) loaned interest profit
    //     // Issue tokens to all stakers
    //     for (uint256 index = 0; index < borrowers.length; index++) {
    //         address recipient = borrowers[index];
    //         uint256 userTotalValue = getUserTotalValue(recipient);
    //         dappToken.transfer(recipient, userTotalValue);
    //     }
    // }

    // function getUserTotalValue(address _user)
    //     public
    //     view
    //     onlyOwner
    //     returns (uint256)
    // {
    //     uint256 totalValue = 0;
    //     // require(numOfNftStaked[_user] > 0, "No nft staked!");
    //     if (numOfNftStaked[_user] <= 0) {
    //         return 0;
    //     }
    //     for (
    //         uint256 nftStakedIndex = 0;
    //         nftStakedIndex < numOfNftStaked[_user];
    //         nftStakedIndex++
    //     ) {
    //         totalValue =
    //             totalValue +
    //             getUserSingleNftValue(
    //                 _user,
    //                 stakedNftAddress[_user][nftStakedIndex],
    //                 stakedNftId[_user][nftStakedIndex]
    //             );
    //     }
    //     return totalValue;
    // }

    // function getUserSingleNftValue(
    //     address _user,
    //     address _nftAddress,
    //     uint256 _nftId
    // ) internal view returns (uint256) {
    //     if (numOfNftStaked[_user] <= 0) {
    //         return 0;
    //     }
    //     (uint256 price, uint256 decimals) = getNftValue(_nftAddress, _nftId);
    //     return (price / (10**decimals));
    //     // 10000000000000000000 ETH
    //     // ETH/USD -> 10000000000
    //     // 10 * 100 = 1,000
    // }

    // function getNftValue(address _nftAddress, uint256 _nftId)
    //     internal
    //     view
    //     returns (uint256, uint256)
    // {
    //     // // default setted to 1ETH and 18decimals
    //     // return (1, 18);

    //     // priceFeedAddress
    //     // address priceFeedAddress = nftPriceFeedMapping[_nftAddress][_nftId];
    //     address priceFeedAddress = nftPriceFeedMapping[_nftAddress];
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         priceFeedAddress
    //     );
    //     (, int256 price, , , ) = priceFeed.latestRoundData();
    //     uint256 decimals = uint256(priceFeed.decimals());
    //     return (uint256(price), decimals);
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}