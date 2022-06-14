/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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

   function safeMint(address to, uint256 tokenId, string memory uri)external;

   function transferOwnership(address NewOwnerAddress)external;
        
}


interface IERC20{
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function totalSupply() external view returns (uint );

    function decimals() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function approve(address sender , uint value)external returns(bool);

    function allowance(address sender, address spender) external view returns (uint256);

    function transfer(address recepient , uint value) external returns(bool);

    function transferFrom(address sender,address recepient, uint value) external returns(bool);

    event Transfer(address indexed from , address indexed to , uint value);

    event Approval(address indexed sender , address indexed  spender , uint value);
}


library incrermentUsingAssemblyLanguageOpcodes{
    function increment(uint numberToIncrement) internal pure returns(uint c){
        assembly{
            c := add(numberToIncrement,1)
        }
        return c;
    }

    function add(uint a, uint b) internal pure returns(uint c){
        assembly{
            c := add(a,b)
        }
        return c;
    }

      function sub(uint a , uint b , string memory errorMessage) internal pure returns(uint){
        uint c = a - b;
        require( c <= a , errorMessage );
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract NFT_MintingPlatform {
    using incrermentUsingAssemblyLanguageOpcodes for uint;

    address public Mint_Owner;
    address public signerAddress;
    // address public USDToken;
    IERC721 public ERC721;
    IERC20 public USDT;

    uint public totalUsersMintedTokenId;
    uint public reffererFee = 5e18;

    mapping(address => bool) public whiteListedUsers;
    mapping(address => mintedUserDetails) public MintedNFTsUserDetails;

    /* Type of Asset for Minting*/
    enum AssetType{
        /* AssetType 0 for ETHER*/
        ETHER,
        /* AssetType 1 for USDT*/
        USDT
    }

    struct Order{
        address toAddr;
        string uri;
        AssetType assetType;
    }

    /* User details. */
    struct mintedUserDetails{
        /* Minter userAddr*/
        address userAddr;
        /* total NFTs minted by this user*/
        uint mintedNFTs;
        /* token ids minted*/
        uint[] tokenIDs;
    }

     /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    event TransferETH(address indexed to, bool result);
    event TransferUSDT(address indexed to, bool result);
    event TransferUSDTFeeToRefferer(address reffererAddress,uint reffererFee);
    event TransferETHFeeToRefferer(address reffererAddress,uint reffererFee);

    modifier OnlyOwner(){
        require(Mint_Owner == msg.sender,"Only Admin!!!");
        _;
    }

  constructor(address SignerAddress,address OwnerAddr, address _ERC721,address _USDToken) {
        require(OwnerAddr != address(0),"Owner can't be zero address!!!");
        assembly{
            sstore(Mint_Owner.slot,OwnerAddr)
            sstore(signerAddress.slot,SignerAddress)
        }
        ERC721 = IERC721(_ERC721);
        USDT = IERC20(_USDToken);
    }

    function mintNFT(Order memory _Order, Sig memory sig,uint USDTokenAmount,address reffererAddress)public payable{
        require(msg.sender != address(0),"Call from zero address!!!");
        require(!whiteListedUsers[msg.sender],"Only WhiteListed user's can mint!!!");
        require(_Order.toAddr != address(0),"Minting can't be done for zero address!!!");

        if(_Order.assetType == AssetType.ETHER){
            require(msg.value == USDTokenAmount,"Deposit ether for Minting NFT!!!");
            require(validateOrderHash(_Order,sig),"Incorrect signature while depositing ETHER!!!");
            uint refferrerFee = getReffererFee(msg.value);
            (bool success,) = Mint_Owner.call{value : msg.value.sub(refferrerFee,"subtraction overflow")}("");
            (bool successs,) = reffererAddress.call{value : refferrerFee}("");
                if(success && successs){
                    totalUsersMintedTokenId = incrermentUsingAssemblyLanguageOpcodes.increment(totalUsersMintedTokenId);
                    mintedUserDetails storage MintedUserdetails = MintedNFTsUserDetails[_Order.toAddr];
                    MintedUserdetails.userAddr = _Order.toAddr;
                    MintedUserdetails.mintedNFTs += 1;
                    MintedUserdetails.tokenIDs.push(totalUsersMintedTokenId);
                        
                    ERC721.safeMint(_Order.toAddr,totalUsersMintedTokenId,_Order.uri);
                    emit TransferETH(_Order.toAddr,success);
                    emit TransferETHFeeToRefferer(reffererAddress,refferrerFee);
                }else{
                    revert("ETH transfer failed");
                }
        }else if(_Order.assetType == AssetType.USDT){
            require(USDTokenAmount > 0,"USDT amount invalid!!!");
            require(validateOrderHash(_Order,sig),"Incorrect signature while depositying USDT!!!");
            uint refferrerFee = getReffererFee(USDTokenAmount);
            (bool successs,) = address(USDT).call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender,Mint_Owner,USDTokenAmount.sub(refferrerFee,"Subtraction overflow!!!")));
            (bool success,) = address(USDT).call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender,reffererAddress,refferrerFee));
                if(success && successs){
                    totalUsersMintedTokenId = incrermentUsingAssemblyLanguageOpcodes.increment(totalUsersMintedTokenId);
                    mintedUserDetails storage MintedUserdetails = MintedNFTsUserDetails[_Order.toAddr];
                    MintedUserdetails.userAddr = _Order.toAddr;
                    MintedUserdetails.mintedNFTs += 1;
                    MintedUserdetails.tokenIDs.push(totalUsersMintedTokenId);
                            
                    ERC721.safeMint(_Order.toAddr,totalUsersMintedTokenId,_Order.uri);
                    emit TransferUSDT(_Order.toAddr,success);
                    emit TransferUSDTFeeToRefferer(reffererAddress,refferrerFee);
                }else{
                    revert("USDT transfer failed");
                }
        }else{
           revert("Invalid assetType!!!");
        }
    }

    function getReffererFee(uint amount)private view returns(uint){
        uint feeAmount = amount.mul(reffererFee).div(100e18,"Division overflow");
        return feeAmount;
    }

    function validateOrderHash(Order memory _Order, Sig memory sig)internal view returns(bool result){
        bytes32 Hash = prepareOrderHash(_Order);
        bytes32 fullMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", Hash)
        );
        address signatoryAddress = ecrecover(fullMessage,sig.v,sig.r,sig.s);
        result = signatoryAddress == signerAddress;
    }

    function prepareOrderHash(Order memory _Order)public pure returns(bytes32){
        return keccak256(
            abi.encodePacked(
                _Order.toAddr,
                _Order.uri,
                _Order.assetType
            )
        );
    }

    function updateSignerAddress(address NewSignerAddress)public OnlyOwner{
        require(NewSignerAddress != address(0),"Zero address can't be signer address!!!");
        signerAddress = NewSignerAddress;
    }

    function updateReffererFeePercentage(uint refFee)public OnlyOwner{
        assembly{sstore(reffererFee.slot,refFee)}
    }

    function addToBlackList(address userAddress) public OnlyOwner{
        require(userAddress != address(0),"Zero address can't be blacklited!!!");
        require(!whiteListedUsers[userAddress],"Already BlackListed this user!!!");
        require(userAddress != Mint_Owner,"Owner can't be blacklisted!!!");
        whiteListedUsers[userAddress] = true;
    }   

    function addToWhiteList(address userAddress) public OnlyOwner{
        require(userAddress != address(0),"Zero address can't be whitelited!!!");
        require(whiteListedUsers[userAddress],"Only BlackListed users can be whiteListed!!!");
        whiteListedUsers[userAddress] = false;
    }

    function transferOwnerShipFromSPN(address NewOwnerAddress)public OnlyOwner{
        require(NewOwnerAddress != address(0), "Ownable: new owner is the zero address!!!");
        ERC721.transferOwnership(NewOwnerAddress);
    }

    function Retrieve(address tokenAddress,uint8 _type,address _toUser,uint amount)public OnlyOwner returns(bool status){
        require(_toUser != address(0), "Invalid Address");
        if (_type == 1) {
            require(address(this).balance >= amount, "Insufficient balance");
            require(payable(_toUser).send(amount), "Transaction failed");
            return true;
        }
        else if (_type == 2) {
            require(IERC20(tokenAddress).balanceOf(address(this)) >= amount);
            IERC20(tokenAddress).transfer(_toUser,amount);
            return true;
        }
        else{
            revert("Invalid AssetType!!!");
        }
    }
}