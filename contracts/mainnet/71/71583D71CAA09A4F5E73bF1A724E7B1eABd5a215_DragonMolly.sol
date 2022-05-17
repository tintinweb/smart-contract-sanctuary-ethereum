//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DragonMolly is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public MAX_PRESALE = 1111;
    uint256 public MAX_FREE = 1000;
    uint256 public maxSupply = 6666;

    uint256 public currentSupply = 0;
    uint256 public maxPerWallet = 5;

    uint256 public salePrice = 0.1 ether;
    uint256 public presalePrice = 0.03 ether;

    uint256 public presaleCount;

    uint256 public freeMinted;

    //Placeholders
    address private presaleAddress = address(0x41451D6448082c4Bb1dED8f7991b02f60738017a);
    address private freeAddress = address(0xaABc53116F0B995BDe9D61556Ef3492043eDbF99);
    address private wallet = address(0x54F22E10Bc5a24B42cb22b1cDdB545aa448d6F35);

    string private baseURI;
    string private notRevealedUri = "ipfs://QmcmyqYcBubUpK2NjXv4K1WDfDefBVP27ikQ9KE5U9Qt4B";

    bool public revealed = false;
    bool public baseLocked = false;
    bool public marketOpened = false;
    bool public freeMintOpened = false;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        Paused,
        Reveal
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public freeMintAccess;
    mapping(address => uint256) public presaleMintLog;
    mapping(address => uint256) public publicMintLog;
    mapping(address => uint256) public freeMintLog;

    constructor()
        ERC721("Dragon Molly", "DragonMolly")
    {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;

        initFree();
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(marketOpened, 'The sale of NFTs on the marketplaces has not been opened yet.');
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(marketOpened, 'The sale of NFTs on the marketplaces has not been opened yet.');
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address( this ).balance;
        
        payable( wallet ).transfer( _balance );
    }

    //GETTERS
    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function getFreeMintAmount( address _acc ) public view returns (uint256) {
        return freeMintAccess[ _acc ];
    }

    function getFreeMintLog( address _acc ) public view returns (uint256) {
        return freeMintLog[ _acc ];
    }

    function validateSignature( address _addr, bytes memory _s ) internal view returns (bool){
        bytes32 messageHash = keccak256(
            abi.encodePacked( address(this), msg.sender)
        );

        address signer = messageHash.toEthSignedMessageHash().recover(_s);

        if( _addr == signer ) {
            return true;
        } else {
            return false;
        }
    }

    //Batch minting
    function mintBatch(
        address to,
        uint256 baseId,
        uint256 number
    ) internal {

        for (uint256 i = 0; i < number; i++) {
            _safeMint(to, baseId + i);
        }

    }

    /**
        Claims tokens for free paying only gas fees
     */
    function freeMint(uint256 _amount, bytes calldata signature) external {
        //Free mint check
        require( 
            freeMintOpened, 
            "Free mint is not opened yet." 
        );

        //Check free mint signature
        require(
            validateSignature(
                freeAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        uint256 supply = currentSupply;
        uint256 allowedAmount = 1;

        if( freeMintAccess[ msg.sender ] > 0 ) {
            allowedAmount = freeMintAccess[ msg.sender ];
        } 

        require( 
            freeMintLog[ msg.sender ] + _amount <= allowedAmount, 
            "You dont have permision to free mint that amount." 
        );

        require(
            supply + _amount <= maxSupply,
            "Molly: Mint too large, exceeding the maxSupply"
        );

        require(
            freeMinted + _amount <= MAX_FREE,
            "Molly: Mint too large, exceeding the free mint amount"
        );


        freeMintLog[ msg.sender ] += _amount;
        freeMinted += _amount;
        currentSupply += _amount;

        mintBatch(msg.sender, supply, _amount);
    }


    function presaleMint(
        uint256 amount,
        bytes calldata signature
    ) external payable {
        
        require(
            workflow == WorkflowStatus.Presale,
            "Molly: Presale is not currently active."
        );

        require(
            validateSignature(
                presaleAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        require(amount > 0, "You must mint at least one token");

        //Max per wallet check
        require(
            presaleMintLog[ msg.sender ] + amount <= maxPerWallet,
            "Molly: You have exceeded the max per wallet amount!"
        );

        //Price check
        require(
            msg.value >= presalePrice * amount,
            "Molly: Insuficient ETH amount sent."
        );
        
        require(
            presaleCount + amount <= MAX_PRESALE,
            "Molly: Selected amount exceeds the max presale supply"
        );

        presaleCount += amount;
        currentSupply += amount;
        presaleMintLog[ msg.sender ] += amount;

        mintBatch(msg.sender, currentSupply - amount, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require( amount > 0, "You must mint at least one NFT.");
        
        uint256 supply = currentSupply;

        require( supply < maxSupply, "Molly: Sold out!" );
        require( supply + amount <= maxSupply, "Molly: Selected amount exceeds the max supply.");

        require(
            workflow == WorkflowStatus.Sale,
            "Molly: Public sale has not active."
        );

        require(
            msg.value >= salePrice * amount,
            "Molly: Insuficient ETH amount sent."
        );

        publicMintLog[ msg.sender ] += amount;
        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    function forceMint(uint256 number, address receiver) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "Molly: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch( receiver, supply, number);
    }

    function ownerMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "Molly: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch(msg.sender, supply, number);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentSupply;
        require(
            supply + addresses.length <= maxSupply,
            "Molly: You can't mint more than max supply"
        );

        currentSupply += addresses.length;

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], supply + i);
        }
    }

    function setUpBefore() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function pauseSale() external onlyOwner {
        workflow = WorkflowStatus.Paused;
    }

    function setMaxPerWallet( uint256 _amount ) external onlyOwner {
        maxPerWallet = _amount;
    }

    function setMaxFree( uint256 _amount ) external onlyOwner {
        MAX_FREE = _amount;
    }

    function setMaxPresale( uint256 _amount ) external onlyOwner {
        MAX_PRESALE = _amount;
    }

    function openFreeMint() public onlyOwner {
        freeMintOpened = true;
    }
    
    function stopFreeMint() public onlyOwner {
        freeMintOpened = false;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require( baseLocked == false, "Base URI change has been disabled permanently");

        baseURI = _newBaseURI;
    }

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setWallet(address _newWallet) public onlyOwner {
        wallet = _newWallet;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        salePrice = _newPrice;
    }
    
    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }
    
    function setFreeMintAccess(address _acc, uint256 _am ) public onlyOwner {
        freeMintAccess[ _acc ] = _am;
    }

    //Lock base security - your nfts can never be changed.
    function lockBase() public onlyOwner {
        baseLocked = true;
    }

    //Once opened, it can not be closed again
    function openMarket() public onlyOwner {
        marketOpened = true;
    }

    // FACTORY
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),'.json'))
                : "";
    }

    function initFree() internal {
        freeMintAccess[ address(0x3fEdc94dB76395a83982277203cB5789ABa955b4) ] = 23;
        freeMintAccess[ address(0xdFA7ae04064eE82378b01FDe8Fcd1aE72cE957a8) ] = 22;
        freeMintAccess[ address(0x793089C3170C6968a7ea0cA42b3E58a12C3F7c22) ] = 15;
        freeMintAccess[ address(0x4c1447148B00692bFd46b9f67A26be44Caa115fA) ] = 13;
        freeMintAccess[ address(0x27F419ea59873fDed5aa65220792EDB6187b5036) ] = 10;
        freeMintAccess[ address(0x919D316475DD4B894E2926Fe2c24B329d8Ade524) ] = 10;
        freeMintAccess[ address(0xE0F6Bb10e17Ae2fEcD114d43603482fcEa5A9654) ] = 10;
        freeMintAccess[ address(0xC6Ac567b250b986acAE49A842Dad7865dA4be3a0) ] = 10;
        freeMintAccess[ address(0x4a9b4cea73531Ebbe64922639683574104e72E4E) ] = 8;
        freeMintAccess[ address(0xE5d08078CA78C9B14101f16fcACbEE8818D06Bfa) ] = 6;
        freeMintAccess[ address(0x7226a4ce2023D5E1228FA55C325bC6D83686c9B7) ] = 6;
        freeMintAccess[ address(0x2132F5a587163540E0858c3258A6813d31fde053) ] = 5;
        freeMintAccess[ address(0xC24838b9077720a30935A73C17d18872E570D7c9) ] = 5;
        freeMintAccess[ address(0x522dC68b2fd2da341d1d25595101E27118B232bD) ] = 5;
        freeMintAccess[ address(0x5c8aD9343c76CCE594cB3B663410DD2fa1aC0e78) ] = 5;
        freeMintAccess[ address(0x2bBD55313F6aFF47638DFe9CbCe59c3428A8C969) ] = 5;
        freeMintAccess[ address(0xc2Ad53Dcdb5A82ce0ed9F165De1BC614031Ff729) ] = 5;
        freeMintAccess[ address(0x12C97D5933f2cFCAA64FdfcC45c89705c89Ca8f1) ] = 5;
        freeMintAccess[ address(0x5b7A238EcE076288D58104AAAB26FA3fbf715957) ] = 5;
        freeMintAccess[ address(0xE170dE7864c63A2442C6FBf5Fff8322D5c72D4fe) ] = 4;
        freeMintAccess[ address(0x6EDf6b0229C9A205d0D0E4f81e6a956e064ECFAa) ] = 4;
        freeMintAccess[ address(0x8813df11Cf5DDc4cFb234eD7Bf78b2CfA9a63Ce5) ] = 4;
        freeMintAccess[ address(0x0081c79304AB6eB2824BDb5f419193ca6d506111) ] = 4;
        freeMintAccess[ address(0xFaeFb5433b70f5D0857cc7f65b32eeae0316aBcb) ] = 4;
        freeMintAccess[ address(0xBaA3f0f0983267D1B9847B6328eDa968Aa5cB0e5) ] = 4;
        freeMintAccess[ address(0xcC0862A45c1c446E62FB99387cEa44Ef4C4FC2D4) ] = 4;
        freeMintAccess[ address(0xb2aF4F684f3B660703f0dc0EabfDe9f8FB185C21) ] = 4;
        freeMintAccess[ address(0xc650846f6D9C7E0EE2A4EaAD6f4Be09789eC7141) ] = 3;
        freeMintAccess[ address(0xd8777f3f65E84CCdca6a4f2C4dCDC1a11030132c) ] = 3;
        freeMintAccess[ address(0x8CEe034078EADd552D0c8E6E80e45A9B3A7A5BE9) ] = 3;
        freeMintAccess[ address(0xc70A3Ad498E0Db94d0752cBF05dC4210aCDa0d1F) ] = 3;
        freeMintAccess[ address(0xCE5443fE2C6B2542C1331Bed2d82f0dd9c14ebbe) ] = 3;
        freeMintAccess[ address(0xa8f6deDCAe4D391Eaa009CB6f848bB31fDB47D02) ] = 3;
        freeMintAccess[ address(0x69e69571d0d07EdBEde6c43849e8d877573eE6bf) ] = 3;
        freeMintAccess[ address(0x40E5529fc270566dD00272af0Bfa684C230cb210) ] = 3;
        freeMintAccess[ address(0x15dB6B0c9D7195d7413f165dCc430cA8F520886c) ] = 3;
        freeMintAccess[ address(0x972f7dB01E68bDa714971a10061B13A563DFF012) ] = 3;
        freeMintAccess[ address(0x065735841E157d74Cd2D69A95d3E4C4003A76E28) ] = 3;
        freeMintAccess[ address(0xc9eD33f42bB0Dc26E7bA76BF61820328F03a3e5f) ] = 3;
        freeMintAccess[ address(0x45896c9885066Fe00D1C9c95B962CD5e6579bAC5) ] = 3;
        freeMintAccess[ address(0x26b7e7a30E75A468cCcC8940D4C5829910aF5073) ] = 3;
        freeMintAccess[ address(0x6BFc87A9559F0d2129C9A418821A6F1Be09d1991) ] = 3;
        freeMintAccess[ address(0x9E75aa8Da215804fa82c8C6b5F24bBb7fF069541) ] = 3;
        freeMintAccess[ address(0x3CB1FE91005B4B92F59D99D2611A0f3C6Ca1aBbb) ] = 3;
        freeMintAccess[ address(0xe120f27AC40AA4f755ebD3781C259425Ad1F9434) ] = 3;
        freeMintAccess[ address(0x400665C0eb68da4564bbbD6A24bBfac65Bd17305) ] = 3;
        freeMintAccess[ address(0xe4aF5C7037D690267bbee5C770ae5D3A1Da70862) ] = 3;
        freeMintAccess[ address(0x4CB764d39555228EAA5dCCB4b7E5bcdBfa417b75) ] = 3;
        freeMintAccess[ address(0xab0281C998BEcD891b0A1Cb443d915Af398Df443) ] = 3;
        freeMintAccess[ address(0xacCB1e0eAa4d6bB3AB8268cFa8fB08d77F082655) ] = 3;
        freeMintAccess[ address(0x6571cb1fc92d71238aE992271D4Fca16e950a40A) ] = 2;
        freeMintAccess[ address(0x05120B86e5ABFEC60a3ba7AbF60D74CF9a7d49e9) ] = 2;
        freeMintAccess[ address(0xdE694b3D3DDC92914F87c8618B067a6306BAcEDA) ] = 2;
        freeMintAccess[ address(0xa215495dB3a2923c74BF570F5253e5Bc05247635) ] = 2;
        freeMintAccess[ address(0x08528a318b20e6213d1b848Baef381B3819c139b) ] = 2;
        freeMintAccess[ address(0x545152C6c3077579702d60A1764a405575F395B2) ] = 2;
        freeMintAccess[ address(0x92b449114420c1b3F10324491727De57809f9Cc8) ] = 2;
        freeMintAccess[ address(0xFc045bFbA2Cc210993DA7D0e5240575Cd4292558) ] = 2;
        freeMintAccess[ address(0x03D98243C825b799E518e1AA4c9314E6614896b2) ] = 2;
        freeMintAccess[ address(0xdC8A96B8613C7f4834F1abC5cf52b0c6FC0730A2) ] = 2;
        freeMintAccess[ address(0xdE3ce6E4bc4967449CD1135a31D5Ae9365E0681d) ] = 2;
        freeMintAccess[ address(0xcEc32F9df33A482A02B80E9e5b41cb4970Bc4976) ] = 2;
        freeMintAccess[ address(0x94c1CB2cecb2a0e9BE3A8C24e11507BE5Ebce172) ] = 2;
        freeMintAccess[ address(0xaC08C1b08430aA3976D6d26E837cd4955e3530aA) ] = 2;
        freeMintAccess[ address(0x20B7A3C7B517e440ffFdfECf505e91D55484072E) ] = 2;
        freeMintAccess[ address(0x392623dfDAAF78C78Df19a92880A2f5F21044365) ] = 2;
        freeMintAccess[ address(0x546630E317b4732870437d9277dd2ed92758805F) ] = 2;
        freeMintAccess[ address(0x7E7c1A3541d2ff134f755ca58512B703906f2785) ] = 2;
        freeMintAccess[ address(0xeE4B71C36d17b1c70E438F8204907C5e068229cc) ] = 2;
        freeMintAccess[ address(0xe1E7A079D5bBFa741f6FA850B9100bAA0B59689C) ] = 2;
        freeMintAccess[ address(0x3C03Fb9387524111D5528eC19B606eF22D107AC0) ] = 2;
        freeMintAccess[ address(0x5F4dF796b08AcAb25dc35b14e4D3Fd0b1588290e) ] = 2;
        freeMintAccess[ address(0xE0f4f6cFb0CD8cE76e99AF76E7018F47E54D414F) ] = 2;
        freeMintAccess[ address(0x75deF0e0adAF2Cad3Ae505fDaD1fd1BeAFdB0A16) ] = 2;
        freeMintAccess[ address(0x02098bf554A48707579FcB28182D42947c013cfA) ] = 2;
        freeMintAccess[ address(0x6C543a1aCa8F972d83e4cD072B5b23Ee49ca77f5) ] = 2;
        freeMintAccess[ address(0x85C26b9287b0b77E41691E12B208396e95f66D2F) ] = 2;
        freeMintAccess[ address(0x4a437b6078Cfb41bC599C4379A9D27259F1948dF) ] = 2;
        freeMintAccess[ address(0xed9A912182745fE101ecb4291D00b802d982Ba0F) ] = 2;
        freeMintAccess[ address(0x68CfFC26438472733803372b7D7Cff58d352DFf4) ] = 2;
        freeMintAccess[ address(0xAeA6880Ea9374c3C5c9805F8CD5c21679df5f9ac) ] = 2;
        freeMintAccess[ address(0x0D57D42C7c784DA53325dA4d4287d39fcd9529de) ] = 2;
        freeMintAccess[ address(0x80Ed258780a60fe518cBc8173566A9eDC8B6598D) ] = 2;
        freeMintAccess[ address(0xC9516b1845e1150dc55B5081Dd072B6c215383A9) ] = 2;
        freeMintAccess[ address(0x8C7EE7fE4871DA8e4C2565B9109dC07a19334b43) ] = 2;
        freeMintAccess[ address(0xFCCB5fa5Aef5481C02fAAA378e663F6259C900fD) ] = 2;
        freeMintAccess[ address(0x52d09189264FaaA709F1AED9C457e55c9e4B5D29) ] = 2;
        freeMintAccess[ address(0xF13Eb1Bc8CD592b3888A67B9EFE73F8Bb41c6142) ] = 2;
        freeMintAccess[ address(0x059a06f9EE4b7D352C0a11E8f0E0995A65f41388) ] = 2;
        freeMintAccess[ address(0x9487a68681F8E114787C97079ed3E8135E12bca6) ] = 2;
        freeMintAccess[ address(0x4dD7957e0499624e65d3fd5B3E217948f2e16d38) ] = 2;
        freeMintAccess[ address(0x6ABaE536325516db0e8e68BAfB06c84FB0a1068d) ] = 2;
        freeMintAccess[ address(0x7C922CDC663367ed2ba6E84c074385121AA79291) ] = 2;
        freeMintAccess[ address(0x827cda8f8A1782040af691B73747AbE2Eeee980b) ] = 2;
        freeMintAccess[ address(0xa71eEA6cfE9f879b05dB8B776e066069419a83be) ] = 2;
        freeMintAccess[ address(0x69287Fa2B775481a43196F298F6aacF5B6A890E7) ] = 2;
        freeMintAccess[ address(0xD13667a9c6990f728610039B8D2a8d4A931308c0) ] = 2;
        freeMintAccess[ address(0x069805bEFFb3deC781aff8b71dB9357Be7ae418c) ] = 2;
        freeMintAccess[ address(0xAD17C670D27096E8a637C2D4471e355A83E9a754) ] = 2;

    }
 
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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