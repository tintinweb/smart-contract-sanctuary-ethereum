// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './interfaces/IAnotherblockV1.sol';
import './interfaces/IERC1155AB.sol';
import './ABErrors.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Storage.sol';

/**
***********************************************************************************************         
***|***************************************************************************************|***                                                                                                                                                                   
***|                                                                                       |***   
***|   NOTE 1:                                                                             |***       
***|   - Do we want to be able to remove drops prior of sold out ?                         |***                                                           
***|                                                                                       |***                                                           
***|   NOTE 2 : DISCUSS                                                                    |***                   
***|   - How do we want to migrate to AnotehrblockV2                                       |***                                               
***|       - Upgrade ? Migration                                                           |***                           
***|       - How to integrate 721 ?                                                        |***                               
***|       - ...                                                                           |***        
***|                                                                                       |***      
***|***************************************************************************************|***                                                                                 
***|***************************************************************************************|***                                                                                 
***|                                                                                       |***
***| TODO 1 : DONE                                                                         |***     
***| - Add setters for as many fields as possible                                          |***                                     
***|                                                                                       |***
***| TODO 2 : DONE                                                                         |***     
***| - Add the possibility to mint _to another address.                                    |***                                             
***|                                                                                       |***
***| TODO 3 : DONE                                                                         |***     
***| - Add separate Max Mint per Address (public sale vs private Sale)                     |***                                                         
***|                                                                                       |***
***| TODO 4 : DONE                                                                         |***     
***| - Remove SharePerToken from 1155AB                                                    |***                             
***|                                                                                       |***
***| TODO 5 : DONE                                                                         |***     
***| - Add _anotherblock address setter in 1155AB                                          |***                                     
***|                                                                                       |***
***| TODO 6 : DONE                                                                         |***
***| - Add support for ERC20 royalty payment                                               |***                                     
***|                                                                                       |***
***|***************************************************************************************|***         
***********************************************************************************************         

**/

contract AnotherblockV1 is Ownable, ReentrancyGuard, ABErrors, ERC165Storage {
    using SafeERC20 for IERC20;

    // Address of anotherblock multisig
    address public treasury;

    // Drop count since genesis
    uint256 private totalDrop = 0;

    // Array of existing Drops
    Drop[] public drops;

    // Last SubId allowed to claim the current payout for a given Drop ID
    mapping(uint256 => uint256) public lastSubIdAllowed;

    // Total ETH deposited for a given Drop ID
    mapping(uint256 => uint256) public totalDeposited;

    // Total amount claimed for a given Drop ID and for a given Sub Token ID
    mapping(uint256 => mapping(uint256 => uint256)) public claimedAmounts;

    // Total amount not to be claimed for a given Drop ID and for a given Sub Token ID (mint post-deposit)
    mapping(uint256 => mapping(uint256 => uint256)) public ignoreAmounts;

    // Event emitted upon Drop creation
    event DropCreated(uint256 dropId);

    // Event emitted upon Drop update
    event DropUpdated(uint256 dropId);

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
     * @param tokenCount : number of different tokenId for this drop
     * @param supply : total number of tokens for this drop (accross all associated tokenId)
     * @param royaltySharePerToken : total percentage of royalty evenly distributed among tokens holders
     */
    struct TokenInfo {
        uint256 price;
        uint256 tokenCount;
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
     * Contract constructor
     */
    constructor(address _treasury) {
        treasury = _treasury;
        _registerInterface(type(IAnotherblockV1).interfaceId);
    }

    /**
     * @notice
     *  Create a Drop
     *  Only the contract owner can perform this operation
     *
     * @param _currencyPayout : address of the currency used for the royalty payout (zero-address if ETH)
     * @param _owner : right holder address
     * @param _nft : NFT contract address
     * @param _price : initial price in ETH(?) of 1 NFT
     * @param _tokenCount : number of different tokenId for this drop
     * @param _supply : total number of NFT for this drop (accross all associated tokenId)
     * @param _royaltySharePerToken : total percentage of royalty evenly distributed among NFT holders
     * @param _rightHolderFee : right Holder fee on each mint expressed in basis point
     * @param _salesInfo : Array of Timestamps at which the private and public sales are opened (in seconds)
     * @param _merkle : merkle tree root used for whitelist
     */
    function create(
        address _currencyPayout,
        address _owner,
        address _nft,
        uint256 _price,
        uint256 _tokenCount,
        uint256 _supply,
        uint256 _royaltySharePerToken,
        uint256 _rightHolderFee,
        uint256[4] calldata _salesInfo,
        bytes32 _merkle
    ) external onlyOwner {
        // Ensure all the Token Ids will have the same number of Tokens
        if (_supply % _tokenCount != 0) revert SupplyToTokenCountRatio();

        // Enfore non-null royalty shares for this drop
        if (_royaltySharePerToken <= 0) revert InsufficientRoyalties();

        // Enfore non-null maximum amount per address
        if (_salesInfo[0] <= 0 || _salesInfo[2] <= 0)
            revert InsufficientMaxAmountPerAddress();

        // Ensure supply non-null
        if (_supply <= 0) revert InsufficientSupply();

        // Ensure right holder address is not the zero address
        if (_owner == address(0)) revert OwnerIsZeroAddress();

        if (
            !ERC165Checker.supportsInterface(_nft, type(IERC1155AB).interfaceId)
        ) revert IncorrectInterface();

        _createDrop(
            _currencyPayout,
            _owner,
            _nft,
            _rightHolderFee,
            TokenInfo(_price, _tokenCount, _supply, _royaltySharePerToken),
            SaleInfo(
                _salesInfo[0],
                _salesInfo[1],
                _salesInfo[2],
                _salesInfo[3]
            ),
            _merkle
        );
    }

    /**
     * @notice
     *  Update the Drop `_dropId` with new `_quantity` recently sold
     *
     * @param _dropId : drop identifier
     * @param _quantity : quantity of NFT sold
     */
    function updateDropDetails(uint256 _dropId, uint256 _quantity) external {
        Drop storage drop = drops[_dropId];

        // Ensure that the caller is the NFT contract associated to this drop
        if (msg.sender != drop.nft) revert UnauthorizedUpdate();

        // For each new token (subId), assign the corresponding ignoreAmounts
        for (uint256 i = 1; i <= _quantity; i++) {
            ignoreAmounts[_dropId][drop.sold + i] =
                totalDeposited[_dropId] /
                drop.tokenInfo.supply;
        }

        // Increment the sold quantity
        drop.sold += _quantity;
    }

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
        uint256 dropSupply;
        uint256 overdue;
        uint256[] memory overdues = new uint256[](_dropIds.length);
        uint256 lastSubIdMinted;
        uint256 uneligibleSupply;
        uint256 totalETHAmount = 0;
        address currencyPayout;

        for (uint256 i = 0; i < _dropIds.length; ++i) {
            // Ensure the drop exsits
            if (_dropIds[i] >= drops.length) revert DropNotFound();

            Drop storage drop = drops[_dropIds[i]];

            // Get the Total Supply for this drop
            dropSupply = drop.tokenInfo.supply;

            // Update the mapping storing the amount of ETH deposited per drop
            totalDeposited[_dropIds[i]] += _amounts[i];

            // Get the last Sub ID minted for this drop
            lastSubIdMinted = IERC1155AB(drop.nft).lastSubIdPerDrop(
                _dropIds[i]
            );

            currencyPayout = drop.currencyPayout;

            // Calculate the uneligible supply (token not minted)
            uneligibleSupply = dropSupply - lastSubIdMinted;

            overdue = 0;
            if (currencyPayout == address(0)) {
                totalETHAmount += _amounts[i];
            } else {
                IERC20(currencyPayout).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amounts[i]
                );
            }

            if (uneligibleSupply > 0) {
                // Calculate the overdue (Total Reward for all uneligible tokens)
                overdue = (_amounts[i] * uneligibleSupply) / dropSupply;

                // Check if payout is in ETH
                if (currencyPayout == address(0)) {
                    // Transfer the ETH overdue to the right holder address
                    payable(_rightHolders[i]).transfer(overdue);
                } else {
                    // Transfer the currency overdue to the right holder address
                    IERC20(currencyPayout).safeTransfer(
                        _rightHolders[i],
                        overdue
                    );
                }
            }

            // Update the mapping storing the lastSubId allowed to claim reward
            lastSubIdAllowed[_dropIds[i]] = lastSubIdMinted;

            // Add the amount of overdue for this drop to the array (for Event log purpose)
            overdues[i] = overdue;
        }

        if (msg.value != totalETHAmount) revert IncorrectDeposit();

        // Emit event upon deposit
        emit Deposited(_dropIds, _amounts, overdues, _rightHolders);
    }

    /**
     * @notice
     *  Claim the amount of reward (in ETH),
     *  for all the Token subId of all the given `_dropIds`
     *
     * @param _dropIds : Array containing all the drop that the user wishes to claim for
     * @param _to : used to delegate claim on behalf of an address
     */
    function claim(uint256[] memory _dropIds, address _to)
        external
        nonReentrant
    {
        uint256[] memory subIds;
        uint256[] memory amountsPerDrop = new uint256[](_dropIds.length);
        uint256 lastSubIdEligible;
        uint256 rewardPerToken;
        uint256 claimableEthAmount = 0;
        bool claimed = false;

        // Iterate over all Drop IDs
        for (uint256 i = 0; i < _dropIds.length; ++i) {
            Drop storage drop = drops[_dropIds[i]];

            // Retrieve the Token subIds owned by the user
            subIds = IERC1155AB(drop.nft).getUserSubIds(_to, _dropIds[i]);

            // Retrieve the last token Sub ID eligible for royalty claim
            lastSubIdEligible = lastSubIdAllowed[_dropIds[i]];

            // Retrieve the amount of reward per token
            rewardPerToken =
                totalDeposited[_dropIds[i]] /
                drop.tokenInfo.supply;

            if (drop.currencyPayout == address(0)) {
                // Iterate over all users' token subIds
                for (uint256 j = 0; j < subIds.length; ++j) {
                    // Ensure the Token SubID is eligible for claim
                    if (subIds[j] <= lastSubIdEligible) {
                        uint256 amountPerSubId = rewardPerToken -
                            claimedAmounts[_dropIds[i]][subIds[j]] -
                            ignoreAmounts[_dropIds[i]][subIds[j]];

                        claimableEthAmount += amountPerSubId;

                        amountsPerDrop[i] += amountPerSubId;

                        claimedAmounts[_dropIds[i]][subIds[j]] = rewardPerToken;
                    }
                }
            } else {
                uint256 claimableAmount = 0;

                // Iterate over all users' token subIds
                for (uint256 j = 0; j < subIds.length; ++j) {
                    // Ensure the Token SubID is eligible for claim
                    if (subIds[j] <= lastSubIdEligible) {
                        uint256 amountPerSubId = rewardPerToken -
                            claimedAmounts[_dropIds[i]][subIds[j]] -
                            ignoreAmounts[_dropIds[i]][subIds[j]];

                        claimableAmount += amountPerSubId;

                        amountsPerDrop[i] += amountPerSubId;

                        claimedAmounts[_dropIds[i]][subIds[j]] = rewardPerToken;
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
        // Check if there are something to claim (revert if not)
        if (claimableEthAmount == 0 && !claimed) {
            revert NothingToClaim();
        } else if (claimableEthAmount != 0) {
            // Pay the claimable amount to `_to`
            payable(_to).transfer(claimableEthAmount);
        }

        // Emit Claimed Event
        emit Claimed(_dropIds, amountsPerDrop, _to);
    }

    /**
     * @notice
     *  Update the treasury address
     *  Only the contract owner can perform this operation
     *
     * @param _newTreasury : new treasury address
     */
    function setTreasury(address _newTreasury) external onlyOwner {
        treasury = _newTreasury;
    }

    /**
     * @notice
     *  Update the Drop `_dropId` sale information
     *  Only the contract owner can perform this operation
     *
     * @param _dropId :  drop identifier of the drop to be updated
     * @param _saleInfo : array containing the new informations to be updated
     */
    function setSalesInfo(uint256 _dropId, uint256[4] calldata _saleInfo)
        external
        onlyOwner
    {
        // Enfore non-null maximum amount per address
        if (_saleInfo[0] <= 0 || _saleInfo[2] <= 0)
            revert InsufficientMaxAmountPerAddress();

        Drop storage drop = drops[_dropId];
        drop.salesInfo.privateSaleMaxMint = _saleInfo[0];
        drop.salesInfo.privateSaleTime = _saleInfo[1];
        drop.salesInfo.publicSaleMaxMint = _saleInfo[2];
        drop.salesInfo.publicSaleTime = _saleInfo[3];

        emit DropUpdated(_dropId);
    }

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
    ) external onlyOwner {
        // Ensure right holder address is not the zero address
        if (_owner == address(0)) revert OwnerIsZeroAddress();

        Drop storage drop = drops[_dropId];
        drop.rightHolderFee = _rightHolderFee;
        drop.owner = _owner;

        emit DropUpdated(_dropId);

    }

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
    function setTokenInfo(uint256 _dropId, uint256[4] calldata _tokenInfo)
        external
        onlyOwner
    {
        // Ensure supply non-null
        if (_tokenInfo[2] <= 0) revert InsufficientSupply();

        // Ensure all the Token Ids will have the same number of Tokens
        if (_tokenInfo[2] % _tokenInfo[1] != 0)
            revert SupplyToTokenCountRatio();

        // Enfore non-null royalty shares for this drop
        if (_tokenInfo[3] <= 0) revert InsufficientRoyalties();

        // Get the drop to be updated
        Drop storage drop = drops[_dropId];

        // Update the price info
        drop.tokenInfo.price = _tokenInfo[0];

        // Update the royalty share info
        drop.tokenInfo.royaltySharePerToken = _tokenInfo[3];

        // Check if the Drop has never been minted and if it is the last drop created
        if (drop.sold == 0 && _dropId == drops[drops.length - 1].dropId) {
            // Update the token Index (from ERC1155AB)
            IERC1155AB(drop.nft).decrementTokenIndex(drop.tokenInfo.tokenCount);
            IERC1155AB(drop.nft).incrementTokenIndex(_tokenInfo[1]);

            // Update the token count info
            drop.tokenInfo.tokenCount = _tokenInfo[1];

            // Update the supply info
            drop.tokenInfo.supply = _tokenInfo[2];
        }
        emit DropUpdated(_dropId);
    }

    /**
     * @notice
     *  Register the Drop information in Drop Struct
     *
     * @param _currencyPayout : address of the currency used for the royalty payout (zero-address if ETH)
     * @param _owner : right holder address
     * @param _nft : NFT contract address
     * @param _rightHolderFee : right Holder fee on each mint expressed in basis point
     * @param _tokenInfo : token information structure (see TokenInfo struct details)
     * @param _salesInfo : Array of Timestamps at which the private and public sales are opened (in seconds)
     * @param _merkle : merkle tree root used for whitelist
     */
    function _createDrop(
        address _currencyPayout,
        address _owner,
        address _nft,
        uint256 _rightHolderFee,
        TokenInfo memory _tokenInfo,
        SaleInfo memory _salesInfo,
        bytes32 _merkle
    ) internal {
        uint256 startTokenIndex = IERC1155AB(_nft).currentTokenIndex();
        drops.push(
            Drop(
                totalDrop,
                0,
                _rightHolderFee,
                startTokenIndex,
                _tokenInfo,
                _salesInfo,
                _currencyPayout,
                _owner,
                _nft,
                _merkle
            )
        );

        // Emit Drop Creation event
        emit DropCreated(totalDrop);

        // Increment the currentTokenIndex state from ERC1155AB contract
        IERC1155AB(_nft).incrementTokenIndex(_tokenInfo.tokenCount);

        // Increment the total drop count
        totalDrop++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAnotherblockV1 {
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
     * @param tokenCount : number of different tokenId for this drop
     * @param supply : total number of tokens for this drop (accross all associated tokenId)
     * @param royaltySharePerToken : total percentage of royalty evenly distributed among tokens holders
     */
    struct TokenInfo {
        uint256 price;
        uint256 tokenCount;
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
     * @param _tokenCount : number of different tokenId for this drop
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
        uint256 _tokenCount,
        uint256 _supply,
        uint256 _royaltySharePerToken,
        uint256 _rightHolderFee,
        uint256 _maxAmountPerAddress,
        uint256[2] calldata _salesInfo,
        bytes32 _merkle
    ) external;

    function updateDropDetails(uint256 _dropId, uint256 _quantity) external;

    /**
     * @notice
     *  Deposit `_amounts` of rewards (in ETH) for the given `_dropIds` to the contract
     *
     * @param _dropIds : array containing the drop identifiers
     * @param _amounts : array containing the amount of ETH for each drop
     * @param _rightHolders : array containing the address of the right holders (to send overdue if needed)
     */
    function depositRewards(
        uint256[] memory _dropIds,
        uint256[] memory _amounts,
        address[] memory _rightHolders
    ) external payable;

    /**
     * @notice
     *  Claim the amount of reward (in ETH),
     *  for all the Token subId of all the given `_dropIds`
     *
     * @param _dropIds : Array containing all the drop that the user wishes to claim for
     * @param _to : used to delegate claim on behalf of an address
     */
    function claim(uint256[] memory _dropIds, address _to) external;

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
    function setTokenInfo(uint256 _dropId, uint256[4] calldata _tokenInfo)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1155AB {
    /**
     * @notice
     *  Update the URI
     *
     * @param _newUri : new URI
     */
    function setURI(string memory _newUri) external;

    /**
     * @notice
     *  Retunrs an array containing all the subId owner by `_user` for the drop `_dropId`
     *
     * @param _user : user address
     * @param _dropId : drop identifier
     */
    function getUserSubIds(address _user, uint256 _dropId)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice
     *  Increment the current token index
     *
     * @param _amount : amount to increment
     */

    function incrementTokenIndex(uint256 _amount) external;

    /**
     * @notice
     *  Decrement the current token index
     *
     * @param _amount : amount to decrement
     */

    function decrementTokenIndex(uint256 _amount) external;

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);

    /**
     * @notice
     *  Withdraw mint proceeds to Anotherblock Treasury address
     *  Only DEFAULT_ADMIN_ROLE can perform this operation
     *
     */
    function withdrawAll() external;

    // Index tracking the Token ID
    function currentTokenIndex() external view returns (uint256);

    // Stores the last Token SubID minted for a given Drop ID
    function lastSubIdPerDrop(uint256 _dropId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract ABErrors {
    // Error returned if `supply` is not a multiple of `tokenCount`
    error SupplyToTokenCountRatio();

    // Error returned if `royaltySharePerToken` is smaller or equal to 0
    error InsufficientRoyalties();

    // Error returned if `maxAmountPerAddress` is smaller or equal to 0
    error InsufficientMaxAmountPerAddress();

    // Error returned if `supply` is smaller or equal to 0
    error InsufficientSupply();

    // Error returned if `owner` address is the zero address
    error OwnerIsZeroAddress();

    // Error returned if the amount deposited is equal to 0
    error EmptyDeposit();

    // Error returned if attempting to deposit reward for an inexistant drop
    error DropNotFound();

    // Error returned if the sum of the _amounts in deposit is different than the ETH sent
    error IncorrectDeposit();

    // Error returned if there is nothing to claim
    error NothingToClaim();

    // Error returned if an unauthorized address attempt to update the drop details
    error UnauthorizedUpdate();

    // Error returned if the contract passed as parameters does not implement the expected interface
    error IncorrectInterface();
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
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
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
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
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
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
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}