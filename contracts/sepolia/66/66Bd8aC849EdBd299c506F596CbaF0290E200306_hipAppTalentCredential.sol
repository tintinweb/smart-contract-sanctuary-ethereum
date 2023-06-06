/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT

/*
****************
 * * **    *  *
* *    ****    *
            **
           *

            **
*   *     *
  *           *
         *
   *   **
    **
 *    *        *
****************

Talent Credential V1.0 2023

Application Interface Contract
Credential Tokenization

Open Source for blockchain scanner
*/
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: Contracts/TalentCredential_v1.0/IhipCONTRACTCredRedeem.sol



/*
****************
[email protected]
 * * **    *  *
* *    ****    *
            **
           *

            **
*   *     *
  *           *
         *
   *   **
    **
 *    *        *
copyright 2022-3
****************

Talent Credential V1.0 2023

Smart Contract 
Interface Functions
*/

pragma solidity ^0.8.17;


//
// ERC1155 NFT Credential for Tokenization with Redemption
// payable
// un-renounced ownership
// enable recovery key
//
interface IhipContractCred is IERC1155 {

    // must include this
    function owner()
        external view returns (address);

    // read back the URI by Token ID
    // override
    function uri(
        uint256 tokenId) 
        external view returns (string memory);


    //
    // initialise ERC20 redeem token contract
    // only owner of this contract
    //
    function adminInitRedeemToken(
        string memory redeemName,
        string memory redeemSymbol,
        uint256 redeemSupply_decimal18,
        address redeemOwner,
        bool resetContract)
        external;


    // mint additional NFT token for more asset edition (new tokenID), or
    // mint more NFT token in the same supply for the existing asset edition (existing tokekID)
    // if token ID already exists > mint more NFT and increase the total supply (e.g. divident)
    // if token ID is new > mint the new NFT with the said total supply (e.g. new edition for sales)
    // not come with ERC20 Redeem Tokens
    // only owner of this contract or the interface
    function adminMintAssetEdition(
        address _editionOwner,
        uint256 _editionId,
        uint256 _editionSupply,
        string memory _editionURI)
        external; 

    //
    // unsafe transfer NFT asset
    // REMARK : Interface Contract calling this function SHOULD add "require (from==_msgSender)"
    // REMARK : because NO allowance(msg.sender) is checked
    // REMARK : and skip checking in safeTransferFrom()
    // REFERENCE : safeTransferFrom() is generally used by Marketplace e.g. opensea
    //
    function unsafeTransferAsset(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data) 
        external;
    // issue (transfer) NFT asset with redemption
    // REMARK : Interface Contract calling this function SHOULD add "require (from==_interfaceAddress)"
    function issueAssetWithRedeemAllowance(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 redeemAllowance_decimal18,      // set or increase the redeem allownace for the new owner of this transferred NFT token
        uint256 timeLockinSeconds,              // this function will add this timeLockinSeconds into block.timestamp to set the real time lock
        bytes memory data) 
        external;

    //
    // Execute redemption of ERC20 redeem token
    // by wrapping (send back) the returned NFT asset to the contract owner
    // REMARK : Interface Contract calling this function SHOULD add "require (from==_msgSender)"
    //
    function wrapAsset2Redeem(
        address fromAssetHolder,
        address toContractOwner,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 redeemAmountAsk_decimal18,        // asking redeem token amount
        bytes memory data) 
        external;
    function checkAssetRedeemAllowance(
        address assetHolder)
        external view returns (uint256);
    function checkAssetRedeemTimelock(
        address assetHolder)
        external view returns (string memory, uint256, uint256);
    function adminResetAssetRedeemAllowanceTimelock(
        address assetHolder,
        uint256 _allowance_decimal18,
        uint256 _timelock)
        external;

    //
    // unsafe transfer of ERC20 redeem token
    // only accessed by owners of this contract or interface contract
    // REMARK : Interface Contract calling this function SHOULD add "require (from==_msgSender)"
    // REMARK : because Interface Contract is the approved spender with all allowance of Redeem Token
    // REMARK : the only-checking is balanceOf[From]
    // REFERENCE : transferFrom() is generally used by wallet e.g. metamask
    // 
    function unsafeTransferRedeem (
        address from,
        address to,
        uint256 amount_decimal18)
        external;

    /////////////////////////////////////////////////////////////////////////////////////////
  
    //
    // view functions for interface contract
    //
    function readAssetDidCredential()
        external view returns (string memory);  
    function readAssetCollectionName()
        external view returns (string memory);
    function readAssetTotalSupply()
        external view returns (uint256);
    function readAssetIdNext()
        external view returns (uint256);
    function readAssetTokenId()
        external view returns (uint256);
    function readRedeemTotalSupply()
        external view returns (uint256);
    function readRedeemBalanceOf(address holder)
        external view returns (uint256);
    function readRedeemName()
        external view returns (string memory);
    function readRedeemSymbol()
        external view returns (string memory);
    function readRedeemDecimals()
        external view returns (uint256);
    function readRedeemContractPool()
        external view returns (address);
    function readRedeemContractOwner()
        external view returns (address);

    //
    // rewrite state variables
    //
    function rewriteAssetDid(
        string memory _assetDidCredential)
        external;


    // write credential into blockchain event ledger
    // only owner of this contract or the interface
    function writeEventCredential(
        address writer,
        string memory text)
        external;


    //
    // Recovery Key to recover the contract ownership
    // with a new owner
    //
    function statusRecoveryKey()
        external view returns(bool);

    //
    // Interface address to this contract
    //
    function statusInterface()
        external view returns(bool);


    // MUST
    // totalSupply() for Polygonscan to read and display 
    // the total supply of this contract
    function totalSupply()
        external view returns (uint256);
    function totalSupply(uint256 id)
        external view returns (uint256);
    // MUST
    // name() for Opensea to read and display
    // the ERC1155 collection name
    function name()
        external view returns (string memory);
    

}



// File: Contracts/TalentCredential_v1.0/hipABSTRACTTalentCredential.sol



/*
****************
 * * **    *  *
* *    ****    *
            **
           *

            **
*   *     *
  *           *
         *
   *   **
    **
 *    *        *
****************

Talent Credential V1.0 2023

Application Interface Contract Abstract
Credential Tokenization

Open Source for blockchain scanner
*/


pragma solidity ^0.8.17;



//
// Interface Contract to access the hip contract 
//
abstract contract hipAbstractTalentCredential is Context {

    // state valuable
    // read interface contract owner
    address public interfaceOwner;

    // state valuable
    // read interacting Real Contract
    IhipContractCred public realContract;
    bool public statusRecoveryKey = false;
    bool public statusContract = false;
    
    // state valuables
    // "about"
    string public aboutContract;
    string public aboutIssuer;
    string public aboutTokenization;
    string public aboutMarketplace;
    string public about;

    //
    // redefine contract ownership
    // modifier for onlyOwner
    //
    modifier onlyInterfaceOwner() {
        _checkInterfaceOwner();
        _;
    }
    function _checkInterfaceOwner() 
        internal view {

        require(
            interfaceOwner == msg.sender, 
            "AppInterface: caller is not the Interface Owner"
        );
    }
    function adminNewInterfaceOwnership(
        address newInterfaceOwner)
        public onlyInterfaceOwner returns (string memory){

        interfaceOwner = newInterfaceOwner;
        return string ("AppInterface ownership transferred");
    }      

    //
    // start or re-start the interface to the Real Contract
    //
    function adminStartRealContract(
        address payable _realContractAddr)
        public onlyInterfaceOwner returns (string memory, address){
        
        require (
            _realContractAddr != address(0), 
            "AppInterface: real Contract cannot be zero address"
        );
        realContract = IhipContractCred(_realContractAddr);
        statusRecoveryKey = realContract.statusRecoveryKey();
        statusContract = realContract.statusInterface();

        string memory realText = "AppInterface to Real Contract started  = ";
        return (realText, _realContractAddr);
    }

    /////////////////////////////////////////////////////////////////////////////////////

    //
    // read Real Contract about values of credential tokenization
    // 
    function read_Issuer_Info()
        public view returns (string memory, string memory, string memory, string memory){

        string memory realText0 = "Issuer Information : [1] Issuer ID, [2] Issuer Name , [3] Issuer Token";
        //uint256 realNumber1 = block.chainid();          // current blockchain ID // still not working for all EVMs
        string memory realText1 = realContract.readAssetDidCredential();
        string memory realText2 = realContract.readAssetCollectionName();
        string memory realText3 = realContract.readRedeemName();
        return (realText0, realText1, realText2, realText3);
    }
    function read_User_Credential_Token()
        public view returns (string memory, string memory, uint256, uint256){

        string memory realText0 = "User Credential Token: [1] Type , [2] Number of Credential minted , [3] Total supply";
        string memory realText1 = "ERC1155";
        uint256 realNumber2 = realContract.readAssetIdNext();
        uint256 realNumber3 = realContract.readAssetTotalSupply();
        return (realText0, realText1, realNumber2, realNumber3);
    }
    // read Real Contract about values of credential redeem token information
    function read_Credential_Redeem_Toekn()
        public view returns (string memory, string memory, string memory, string memory, uint256, uint256){

        string memory realText0 = "Credential Redeem Token : [1] Type , [2] Name , [3] Symbol , [4] Decimals , [5]  Supply";
        string memory realText1 = "ERC20";
        string memory realText2 = realContract.readRedeemName();
        string memory realText3 = realContract.readRedeemSymbol();
        uint256 realNumber4 = realContract.readRedeemDecimals();
        uint256 realNumber5 = realContract.readRedeemTotalSupply();  
        return (realText0, realText1, realText2, realText3, realNumber4, realNumber5);
    }
    // read Real Contract about the pool information
    function read_ContractPool()
        public view returns (string memory, address, address, string memory, address, address){

        string memory realText0 = "Credential NFT Contract Addresses : [1] Contract Owner, [2] Contract Pool";
        address realAddr1 = realContract.owner();
        address realAddr2 = address(realContract);
        string memory realText3 = "Credential Redeem Contract Addresses : [4] Contract Owner, [5] Contract Pool";
        address realAddr4 = realContract.readRedeemContractOwner();
        address realAddr5 = realContract.readRedeemContractPool();
        return (realText0, realAddr1, realAddr2, realText3, realAddr4, realAddr5);
    }
    // read token holder's balance
    function read_Holder_BalanceOf(
        address _tokenHolder)
        public view returns (string memory, uint256, uint256, uint256){

        string memory realText0 = "Token balance of this holder : [1] Asset , [2] Redeem Allowance, [3] Redeem Claimed";
        uint256 realNumber1 = realContract.balanceOf(_tokenHolder, 1);            // ERC1155.balancOf TOKEN ID = 1
        uint256 realNumber2 = realContract.checkAssetRedeemAllowance(_tokenHolder);
        uint256 realNumber3 = realContract.readRedeemBalanceOf(_tokenHolder);     // ERC20.balanceOf
        return (realText0, realNumber1, realNumber2, realNumber3);
    }
    function read_Token_BalanceOf(
        address _tokenHolder,
        uint256 _tokenId)
        public view returns (string memory, uint256, uint256, uint256, uint256){

        string memory realText0 = "Token balance of this holder : [1] Token ID , [2] Asset|Edition , [3] Redeem Allowance, [4] Redeem Claimed";
        uint256 realNumber2 = realContract.balanceOf(_tokenHolder, _tokenId);     // ERC1155.balancOf
        uint256 realNumber3 = realContract.checkAssetRedeemAllowance(_tokenHolder);
        uint256 realNumber4 = realContract.readRedeemBalanceOf(_tokenHolder);     // ERC20.balanceOf
        return (realText0, _tokenId, realNumber2, realNumber3, realNumber4);
    }

    //
    // write About
    // only owner of this interface contract
    //
    function adminWriteAboutAll(
        string memory _aboutContract,
        string memory _aboutIssuer,
        string memory _aboutTokenization,
        string memory _aboutMarketplace,
        string memory _about)
        public onlyInterfaceOwner{

        if (bytes(_aboutContract).length > 0)     
            aboutContract = _aboutContract;
        if (bytes(_aboutIssuer).length > 0)     
            aboutIssuer = _aboutIssuer;
        if (bytes(_aboutTokenization).length > 0)     
            aboutTokenization = _aboutTokenization;
        if (bytes(_aboutMarketplace).length > 0)     
            aboutMarketplace = _aboutMarketplace;
        if (bytes(_about).length > 0)     
            about = _about;
        else
            about = "User Credential Tokenization by Issuer";
    }

    /////////////////////////////////////////////////////////////////////////////////////

    //
    // Message sender to transfer ERC1155/ERC721 Asset Token 
    // to other account
    // not to contract owner
    //
    // REMARK : Interface Contract calling unsafeTransferAsset() SHOULD add "require (from==_msgSender)"
    // REMARK : because NO allowance(msg.sender) is checked
    // REMARK : and skip checking in safeTransferFrom()
    //   
    function transfer_AssetToken(
        //address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data) 
        public virtual {

        require (
          to != interfaceOwner,
          "RealInterface: cannot send to owner of this interface contract, use claimRedemption()"
        );
        require (
          to != realContract.owner(),
          "RealInterface: cannot send to owner of the real contract, use claimRedemption()"
        );
        address from = msg.sender;
        realContract.unsafeTransferAsset(from, to, id, amount, data);
    }

    //
    // Message sender to transfer ERC20 Redeem Token 
    // to any other account
    //
    // REMARK : Interface Contract calling unsafeTransferRedeem SHOULD add "require (from==_msgSender)"
    // REMARK : because Interface Contract is the approved spender with all allowance of Redeem Token
    // REMARK : the only-checking is balanceOf[From]
    //
    function transfer_RedeemToken(
        //address from,
        address to,
        uint256 amount_decimal18)
        public virtual{

        address from = msg.sender;
        realContract.unsafeTransferRedeem (from, to, amount_decimal18);       // ERC20.transferFrom     
    } 


    //
    // Claim redemption
    // 1. send back Asset Token to Owner of real contract
    // 2. ask for amount of redeem token
    // 3. wrap Asset token and send redeem token to msg.sender
    //
    function check_Redeem_Allowance()
        //address assetHolder)
        public view virtual returns(string memory, uint256) {

        address assetHolder = msg.sender;
        uint256 _allowance = realContract.checkAssetRedeemAllowance(assetHolder);
        string memory realText = "Allowance of Redemption in decimals of 18 = ";
        return (realText, _allowance);
    }
    function check_Redeem_Timelock()
        //address assetHolder)
        public view virtual returns(string memory, uint256, string memory, uint256) {

        address assetOwner = msg.sender;
        (,uint256 _timelock,) = realContract.checkAssetRedeemTimelock(assetOwner);
        string memory realText0 = "Timelock of Redemption : ";
        string memory realText1 = "Current Block Time (in seconds) : ";
        return (realText0, _timelock, realText1, block.timestamp);
    }

    // REMARK : Interface Contract calling this function SHOULD add "require (from==_msgSender)"
    function claim_Redemption(
        address fromAssetHolder,
        //address toContractOwner,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 redeemAmountAsk_decimal18)        // asking redeem token amount
        public virtual {

        require (
            fromAssetHolder == msg.sender,
            "RealInterface: claim redemption should be from message sender who is the owner too"
        );
        address toContractOwner = realContract.owner();
        realContract.wrapAsset2Redeem(
            fromAssetHolder,
            toContractOwner,
            tokenId,
            tokenAmount,
            redeemAmountAsk_decimal18,        
            "0x00"
        );
    }

    /////////////////////////////////////////////////////////////////////////////////////
    // Compiler options

    //
    // transfer Divident/Redeem token to [email protected] 
    // from the Real Contract owner only
    //
    // REMARK : Interface Contract calling unsafeTransferRedeem SHOULD add "require (from==_msgSender)"
    // REMARK : because Interface Contract is the approved spender with all allowance of Redeem Token
    // REMARK : the only-checking is balanceOf[From]
    //
    function adminTransferRedeemFromPool2Sender(
        address fromContractOwner,
        //address to,
        uint256 redeemAmount_decimal18) 
        public virtual{

        // firstly need real contract owner to execute 
        //   approval (this.address, amount)
        // for this interface contract to call transferFrom()
        require(
            msg.sender == interfaceOwner, 
            "RealInterface: message sender is not the Contract owner"
        );
        require(
            fromContractOwner == realContract.owner(), 
            "RealInterface: owner sender is not the Real Contract owner"
        );
        address to = msg.sender;
        
        // firstly need msg.sender to execute 
        //   approval (this.address, amount)
        // for this interface contract on the real contract
        realContract.unsafeTransferRedeem (fromContractOwner, to, redeemAmount_decimal18);  // ERC20.transferFrom     
    } 


    // mint & transfer MORE Asset NFT token as Utility to msg.sender 
    // from the Real Contract owner
    // only original NFT asset at assetId.ID_ASSET = 1
    function adminMintTransferMoreAssetToken(
        address to,
        uint256 moreSupply) 
        public virtual{

        // restricted to Real Contract owner > msg.sender at assetId.ID_ASSET only
        require(
          msg.sender == interfaceOwner, 
          "RealInterface: message sender is not the Contract owner"
        );
        uint256 _tokenId = realContract.readAssetTokenId(); 
        string memory _uri = realContract.uri(_tokenId);

        // mint new NFT token
        realContract.adminMintAssetEdition(to, _tokenId, moreSupply, _uri);      // ERC1155.mint
    } 

    // mint additional Asset Edition on top of the first NFT
    // auto tokenId > 1
    function adminMintAssetEdition(
        address editionOwner,
        //uint256 editionId,
        string memory editionURI,
        uint256 editionSupply)
        public virtual returns (uint256, uint256){

        require(
          msg.sender == interfaceOwner, 
          "RealInterface: message sender is not the Contract owner"
        );
        uint256 _editionId = realContract.readAssetIdNext();
        require (
          _editionId != 1, 
          "Next Token ID starts from 2");
        realContract.adminMintAssetEdition(editionOwner, _editionId, editionSupply, editionURI);

        //string memory realText0 = "New edition minted [Token ID , New Total Supply]";
        uint256 realNumber1 = _editionId;
        uint256 realNumber2 = realContract.readAssetTotalSupply();
        return (realNumber1, realNumber2);
    }    

}

// File: Contracts/TalentCredential_v1.0/hipAPPTalentCredential.sol



/*
****************
 * * **    *  *
* *    ****    *
            **
           *

            **
*   *     *
  *           *
         *
   *   **
    **
 *    *        *
****************

Talent Credential V1.0 2023

Application Interface Contract
Credential Tokenization

Open Source for blockchain scanner
*/

pragma solidity ^0.8.17;



//
// Interface Contract to access the hip contract
// whole application interface = hipAppTalentCredential + hipAbstractTalentCredential
//
contract hipAppTalentCredential is hipAbstractTalentCredential {

    // state variables
    // data base for search
    mapping (address => string) public addr2Metadata;
    mapping (address => string) public addr2ImageUrl;

    // constructor of this Application Interface
    // is always the default owner transferrable
    constructor() {

        interfaceOwner = msg.sender;
    }

    // write holder's metadata for search
    function adminSetAddr2Metadata(
        address holder, 
        string memory data) 
        public {

        addr2Metadata[holder] = data; 
    }
    // write holder's image URL for search
    function adminSetAddr2ImageUrl(
        address holder, 
        string memory data) 
        public {

        addr2ImageUrl[holder] = data; 
    }



    /////////////////////////////////////////////////////////////////////////////////////
    // Compiler options
    // Duplicated and renamed functions

    //
    // transfer Divident/Redeem token to [email protected] 
    // from the Real Contract owner only
    //
    // REMARK : Interface Contract calling unsafeTransferRedeem SHOULD add "require (from==_msgSender)"
    // REMARK : because Interface Contract is the approved spender with all allowance of Redeem Token
    // REMARK : the only-checking is balanceOf[From]
    //
    function offeringHolderReceiveBonus(
        address fromPool,
        //address to,
        uint256 redeemBonus_decimal18) 
        public {

        adminTransferRedeemFromPool2Sender(
          fromPool,
          //address to,
          redeemBonus_decimal18
        );  
    } 


    // mint & transfer MORE credential NFT token as Utility to msg.sender 
    // from the Real Contract owner
    // only original NFT asset at assetId.ID_ASSET = 1
    function offeringOwnerMintMoreCredentialToken(
        address toHolder,
        uint256 moreSupply) 
        public {

        adminMintTransferMoreAssetToken(
          toHolder,
          moreSupply
        ); 
    } 

    // mint additional credential NFT on top of the first NFT
    // auto tokenId > 1
    function offeringOwnerMintNewCredentialToken(
        address editionOwner,
        string memory editionURI,
        uint256 editionSupply)
        public virtual returns (string memory, uint256, uint256){

        (uint256 _editionId, uint256 _newTotalSupply) = 
        adminMintAssetEdition(
            editionOwner,
            //editionId,
            editionURI,
            editionSupply
        );

        string memory realText0 = "New token of Credential minted [Token ID , New total Supply]";
        uint256 realNumber1 = _editionId;
        uint256 realNumber2 = _newTotalSupply;
        return (realText0, realNumber1, realNumber2);
    }    

    //
    /////////////////////////////////////////////////////////////////////////////////////

}