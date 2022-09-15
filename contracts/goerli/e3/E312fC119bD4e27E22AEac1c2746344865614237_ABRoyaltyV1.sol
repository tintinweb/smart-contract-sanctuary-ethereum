//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//
//
//  █████╗ ███╗   ██╗ ██████╗ ████████╗██╗  ██╗███████╗██████╗ ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ██╔══██╗████╗  ██║██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ███████║██╔██╗ ██║██║   ██║   ██║   ███████║█████╗  ██████╔╝██████╔╝██║     ██║   ██║██║     █████╔╝
// ██╔══██║██║╚██╗██║██║   ██║   ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══██╗██║     ██║   ██║██║     ██╔═██╗
// ██║  ██║██║ ╚████║╚██████╔╝   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
// ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
//
/**
 * @title ABRoyaltyV1 Contract
 * @author Anotherblock Technical Team
 * @notice This contract is responsible for depositing & claiming Music Streaming royalty from anotherblock.io
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './interfaces/IABDropManager.sol';
import './interfaces/IERC721AB.sol';
import './ABErrors.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract ABRoyaltyV1 is Ownable, ReentrancyGuard, ABErrors {
    using SafeERC20 for IERC20;

    // AnotherblockV1 address
    address public anotherblock;

    // Last TokenId allowed to claim the current payout for a given Drop ID
    mapping(uint256 => uint256) public lastTokenIdAllowed;

    // Total ETH deposited for a given Drop ID
    mapping(uint256 => uint256) public totalDeposited;

    // Total amount claimed for a given Token ID
    mapping(uint256 => uint256) public claimedAmounts;

    // Total amount not to be claimed for a given Token ID (mint post-deposit)
    mapping(uint256 => uint256) public ignoreAmounts;

    // Event emitted once royalties had been deposited and overdue paid to right holders
    event Deposited(
        uint256[] dropIds,
        uint256[] amounts,
        uint256[] overdues,
        address[] rightHolders
    );

    // Event emitted once user has claimed its royalties
    event Claimed(uint256[] dropIds, uint256[] amounts, address beneficiary);

    /**
     * @notice
     *  ABRoyaltyV1 contract constructor
     *
     * @param _anotherblock : Anotherblock contract address
     **/
    constructor(address _anotherblock) {
        anotherblock = _anotherblock;
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Claim the amount of reward (in ETH or in Current Payout ERC20),
     *  for all the Token ID minted of all the given `_dropIds`
     *
     * @param _dropIds : Array containing all the drop that the user wishes to claim for
     * @param _to : used to delegate claim on behalf of an address
     */
    function claim(uint256[] memory _dropIds, address _to)
        external
        nonReentrant
    {
        // Check that _to is not the Zero-address
        if (_to == address(0)) revert ZeroAddress();

        uint256[] memory amountsPerDrop = new uint256[](_dropIds.length);
        uint256[] memory tokenIds;
        uint256 rewardPerToken;
        uint256 claimableEthAmount = 0;
        bool claimed = false;

        // Iterate over all Drop IDs
        for (uint256 i = 0; i < _dropIds.length; ++i) {
            IABDropManager.Drop memory drop = IABDropManager(anotherblock)
                .drops(_dropIds[i]);

            // Retrieve the Token Ids owned by the user
            tokenIds = IERC721AB(drop.nft).tokensOfOwner(_to);

            // Retrieve the amount of reward per token
            rewardPerToken =
                totalDeposited[_dropIds[i]] /
                drop.tokenInfo.supply;

            if (drop.currencyPayout == address(0)) {
                // Iterate over all users' token IDs
                for (uint256 j = 0; j < tokenIds.length; ++j) {
                    // Ensure the Token ID is eligible for claim and correspond to dropIds[i]
                    if (
                        tokenIds[j] >= drop.firstTokenIndex &&
                        tokenIds[j] <= lastTokenIdAllowed[_dropIds[i]]
                    ) {
                        uint256 amountPerToken = rewardPerToken -
                            claimedAmounts[tokenIds[j]] -
                            ignoreAmounts[tokenIds[j]];

                        claimableEthAmount += amountPerToken;

                        amountsPerDrop[i] += amountPerToken;

                        claimedAmounts[tokenIds[j]] = rewardPerToken;
                    }
                }
            } else {
                uint256 claimableAmount = 0;

                // Iterate over all users' token IDs
                for (uint256 j = 0; j < tokenIds.length; ++j) {
                    // Ensure the Token ID is eligible for claim
                    if (
                        tokenIds[j] >= drop.firstTokenIndex &&
                        tokenIds[j] <= lastTokenIdAllowed[_dropIds[i]]
                    ) {
                        uint256 amountPerToken = rewardPerToken -
                            claimedAmounts[tokenIds[j]] -
                            ignoreAmounts[tokenIds[j]];

                        claimableAmount += amountPerToken;

                        amountsPerDrop[i] += amountPerToken;

                        claimedAmounts[tokenIds[j]] = rewardPerToken;
                    }
                }
                if (claimableAmount > 0) {
                    claimed = true;
                    IERC20(drop.currencyPayout).safeTransfer(
                        _to,
                        claimableAmount
                    );
                }
            }
        }
        // Emit Claimed Event
        emit Claimed(_dropIds, amountsPerDrop, _to);

        // Check if there are something to claim (revert if not)
        if (claimableEthAmount == 0 && !claimed) {
            revert NothingToClaim();
        } else if (claimableEthAmount != 0) {
            // Pay the claimable amount to `_to`
            payable(_to).transfer(claimableEthAmount);
        }
    }

    //
    //     ____        __         ____                              ______                 __  _
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____   / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/     /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
    //               /____/

    /**
     * @notice
     *  Deposit `_amounts` of rewards (in ETH) for the given `_dropIds` to the contract
     *  Only the contract owner can perform this operation
     *
     * @param _dropIds : array containing the drop identifiers
     * @param _amounts : array containing the amount of ETH for each drop
     * @param _rightHolders : array containing the address of the right holders (to send overdue if needed)
     */
    function depositRewards(
        uint256[] memory _dropIds,
        uint256[] memory _amounts,
        address[] memory _rightHolders
    ) public payable onlyOwner {
        uint256 overdue;
        uint256[] memory overdues = new uint256[](_dropIds.length);
        uint256 uneligibleSupply;
        uint256 newlyMintedQuantity;
        uint256 totalETHAmount = 0;

        for (uint256 i = 0; i < _dropIds.length; ++i) {
            IABDropManager.Drop memory drop = IABDropManager(anotherblock)
                .drops(_dropIds[i]);

            if (lastTokenIdAllowed[_dropIds[i]] != 0) {
                newlyMintedQuantity =
                    drop.firstTokenIndex +
                    drop.sold -
                    1 -
                    lastTokenIdAllowed[_dropIds[i]];

                // For each newly minted token, assign the corresponding ignoreAmounts
                for (uint256 j = 0; j < newlyMintedQuantity; j++) {
                    ignoreAmounts[drop.firstTokenIndex + drop.sold - j - 1] =
                        totalDeposited[_dropIds[i]] /
                        drop.tokenInfo.supply;
                }
            }
            // Update the mapping storing the amount of ETH deposited per drop
            totalDeposited[_dropIds[i]] += _amounts[i];

            // Update the mapping storing the last token ID allowed to claim reward for this payout
            lastTokenIdAllowed[_dropIds[i]] =
                drop.firstTokenIndex +
                drop.sold -
                1;

            // Calculate the uneligible supply (token not minted)
            uneligibleSupply = drop.tokenInfo.supply - drop.sold;

            overdue = 0;
            if (drop.currencyPayout == address(0)) {
                totalETHAmount += _amounts[i];
            } else {
                IERC20(drop.currencyPayout).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amounts[i]
                );
            }

            if (uneligibleSupply > 0) {
                // Calculate the overdue (Total Reward for all uneligible tokens)
                overdue =
                    (_amounts[i] * uneligibleSupply) /
                    drop.tokenInfo.supply;

                // Check if payout is in ETH
                if (drop.currencyPayout == address(0)) {
                    // Transfer the ETH overdue to the right holder address
                    payable(_rightHolders[i]).transfer(overdue);
                } else {
                    // Transfer the currency overdue to the right holder address
                    IERC20(drop.currencyPayout).safeTransfer(
                        _rightHolders[i],
                        overdue
                    );
                }
            }

            // Add the amount of overdue for this drop to the array (for Event log purpose)
            overdues[i] = overdue;
        }

        if (msg.value != totalETHAmount) revert IncorrectDeposit();

        // Emit event upon deposit
        emit Deposited(_dropIds, _amounts, overdues, _rightHolders);
    }

    /**
     * @notice
     *  Withdraw funds from this contract to Anotherblock Treasury address
     *  Only the contract owner can perform this operation
     *
     */
    function emergencyWithdraw() external onlyOwner {
        payable(IABDropManager(anotherblock).treasury()).transfer(
            address(this).balance
        );
    }

    /**
     * @notice
     *  Withdraw ERC20 from this contract to Anotherblock Treasury address
     *  Only the contract owner can perform this operation
     *
     */
    function emergencyWithdrawERC20(address _erc20) external onlyOwner {
        IERC20(_erc20).safeTransfer(
            IABDropManager(anotherblock).treasury(),
            IERC20(_erc20).balanceOf(address(this))
        );
    }
}

//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████    
//                            ████████████████████████          ██████████        
//                            ████████████████████████          ██████████        
//                            ████████████████████████          ██████████        
//                            ████████████████████████          ██████████        
//                                                    ████████████████████ 
//                                                    ████████████████████ 
//                                                    ████████████████████            
//                                                    ████████████████████
//
//
//  █████╗ ███╗   ██╗ ██████╗ ████████╗██╗  ██╗███████╗██████╗ ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ██╔══██╗████╗  ██║██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ███████║██╔██╗ ██║██║   ██║   ██║   ███████║█████╗  ██████╔╝██████╔╝██║     ██║   ██║██║     █████╔╝ 
// ██╔══██║██║╚██╗██║██║   ██║   ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══██╗██║     ██║   ██║██║     ██╔═██╗ 
// ██║  ██║██║ ╚████║╚██████╔╝   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
// ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝                                                                                             
//
/**
 * @title IABDropManager
 * @author Anotherblock Technical Team
 * @notice ABDropManager Interface
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IABDropManager {
    /**
     * @notice
     *  Drop Structure format
     *
     * @param dropId : drop unique identifier
     * @param sold : total number of sold tokens for this drop (accross all associated tokenId)
     * @param rightHolderFee : right Holder fee on each mint expressed in basis point
     * @param firstTokenIndex : TokenId at which this drop starts
     * @param salesInfo : Sale Info struct defining the private and public sales opening date
     * @param tokenInfo : Token Info struct defining the token information (see TokenInfo structure)
     * @param currencyPayout : address of the currency used for the royalty payout (zero-address if ETH)
     * @param owner : right holder address
     * @param nft :  NFT contract address
     * @param merkleRoot : merkle tree root used for whitelist
     */
    struct Drop {
        uint256 dropId;
        uint256 sold;
        uint256 rightHolderFee;
        uint256 firstTokenIndex;
        TokenInfo tokenInfo;
        SaleInfo salesInfo;
        address currencyPayout;
        address owner;
        address nft;
        bytes32 merkleRoot;
    }

    /**
     * @notice
     *  TokenInfo Structure format
     *
     * @param price : initial price in ETH(?) of 1 token
     * @param supply : total number of tokens for this drop (accross all associated tokenId)
     * @param royaltySharePerToken : total percentage of royalty evenly distributed among tokens holders
     */
    struct TokenInfo {
        uint256 price;
        uint256 supply;
        uint256 royaltySharePerToken;
    }

    /**
     * @notice
     *  SaleInfo Structure format
     *
     * @param privateSaleMaxMint : Maximum number of token to be minted per address for the private sale
     * @param privateSaleTime : timestamp at which the private sale is opened
     * @param publicSaleMaxMint : Maximum number of token to be minted per address for the public sale
     * @param publicSaleTime : timestamp at which the public sale is opened
     */
    struct SaleInfo {
        uint256 privateSaleMaxMint;
        uint256 privateSaleTime;
        uint256 publicSaleMaxMint;
        uint256 publicSaleTime;
    }

    /**
     * @notice
     *  Returns Anotherblock Treasury address
     *
     */
    function treasury() external view returns (address);

    /**
     * @notice
     *  Returns the drop `_dropId`
     *
     * @param _dropId : drop identifier
     */
    function drops(uint256 _dropId) external view returns (Drop memory);

    /**
     * @notice
     *  Create a Drop
     *
     * @param _owner : right holder address
     * @param _nft : NFT contract address
     * @param _price : initial price in ETH(?) of 1 NFT
     * @param _supply : total number of NFT for this drop (accross all associated tokenId)
     * @param _royaltySharePerToken : total percentage of royalty evenly distributed among NFT holders
     * @param _rightHolderFee : right Holder fee on each mint expressed in basis point
     * @param _maxAmountPerAddress : Maximum number of token to be minted per address
     * @param _salesInfo : Array of Timestamps at which the private and public sales are opened (in seconds)
     * @param _merkle : merkle tree root used for whitelist
     */
    function create(
        address _owner,
        address _nft,
        uint256 _price,
        uint256 _supply,
        uint256 _royaltySharePerToken,
        uint256 _rightHolderFee,
        uint256 _maxAmountPerAddress,
        uint256[2] calldata _salesInfo,
        bytes32 _merkle
    ) external;

    function updateDropCounter(uint256 _dropId, uint256 _quantity) external;

    /**
     * @notice
     *  Update the treasury address
     *  Only the contract owner can perform this operation
     *
     * @param _newTreasury : new treasury address
     */
    function setTreasury(address _newTreasury) external;

    /**
     * @notice
     *  Update the Drop `_dropId` sale information
     *  Only the contract owner can perform this operation
     *
     * @param _dropId :  drop identifier of the drop to be updated
     * @param _saleInfo : array containing the new informations to be updated
     */
    function setSalesInfo(uint256 _dropId, uint256[4] calldata _saleInfo)
        external;

    /**
     * @notice
     *  Update the Drop `_dropId` drop information
     *  Only the contract owner can perform this operation
     *
     * @param _dropId :  drop identifier of the drop to be updated
     * @param _rightHolderFee : fees paid to right holder
     * @param _owner : right holder address
     */
    function setRightHolderInfo(
        uint256 _dropId,
        uint256 _rightHolderFee,
        address _owner
    ) external;

    /**
     * @notice
     *  Update the Drop `_dropId` token information
     *  Only the contract owner can perform this operation
     *
     *  Return true if `tokenCount` and `supply` are updated, false otherwise
     *
     * @param _dropId :  drop identifier of the drop to be updated
     * @param _tokenInfo : array containing the new informations to be updated
     */
    function setTokenInfo(uint256 _dropId, uint256[3] calldata _tokenInfo)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC721AB {
    /**
     * @notice
     *  Update anotherblock address
     *  Revoke the AB_ROLE from the previous anotherblock address
     *  Grant the AB_ROLE role to the new address
     *  Only DEFAULT_ADMIN_ROLE can perform this operation
     *
     * @param _anotherblock : new anotherblock address
     */
    function setAnotherblock(address _anotherblock) external;

    /**
     * @notice
     *  Return an array containing the token IDs owned by the given address
     *
     * @param _owner : owner address
     * @return result : array containing all the token IDs owned by `_owner`
     */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function dropIdPerToken(uint256 _tokenId) external returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//
//
//  █████╗ ███╗   ██╗ ██████╗ ████████╗██╗  ██╗███████╗██████╗ ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ██╔══██╗████╗  ██║██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ███████║██╔██╗ ██║██║   ██║   ██║   ███████║█████╗  ██████╔╝██████╔╝██║     ██║   ██║██║     █████╔╝
// ██╔══██║██║╚██╗██║██║   ██║   ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══██╗██║     ██║   ██║██║     ██╔═██╗
// ██║  ██║██║ ╚████║╚██████╔╝   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
// ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
//
/**
 * @title ABErrors
 * @author Anotherblock Technical Team
 * @notice AnotherblockV1 Custom Errors contract
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ABErrors {
    /**
    @notice Error returned if `royaltySharePerToken` is smaller or equal to 0
    **/
    error InsufficientRoyalties();

    /**
    @notice Error returned if `maxAmountPerAddress` is smaller or equal to 0
    **/
    error InsufficientMaxAmountPerAddress();

    /**
    @notice Error returned if `supply` is smaller or equal to 0
    **/
    error InsufficientSupply();

    /**
    @notice Error returned if `owner` address is the zero address
    **/
    error ZeroAddress();

    /**
    @notice Error returned if the amount deposited is equal to 0
    **/
    error EmptyDeposit();

    /**
    @notice Error returned if attempting to deposit reward for an inexistant drop
    **/
    error DropNotFound();

    /**
    @notice Error returned if the sum of the _amounts in deposit is different than the ETH sent
    **/
    error IncorrectDeposit();

    /**
    @notice Error returned if there is nothing to claim
    **/
    error NothingToClaim();

    /**
    @notice Error returned if an unauthorized address attempt to update the drop details
    **/
    error UnauthorizedUpdate();

    /**
    @notice Error returned if the contract passed as parameters does not implement the expected interface
    **/
    error IncorrectInterface();
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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