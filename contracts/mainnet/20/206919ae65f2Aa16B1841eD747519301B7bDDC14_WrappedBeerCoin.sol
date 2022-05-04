// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "BeerCoinOrigContract.sol";
import "BeerCoinHolder.sol";


contract WrappedBeerCoin is ERC721, ERC721Enumerable, Ownable {

    event Wrapped(uint256 indexed pairId, address indexed owner);
    event Unwrapped(uint256 indexed pairId, address indexed owner);

    BeerCoinOrigContract bcContract = BeerCoinOrigContract(0x74C1E4b8caE59269ec1D85D3D4F324396048F4ac);

    uint256 constant numPairs = 77;
    struct bcPair {
        address debtor;
        address creditor;
        uint256 numBeers;
        address holderAddr;
        bool wrapped;
    }
    mapping(uint256 => bcPair) public pairs;
    mapping(address => mapping(address => uint256)) public indexes;
    
    constructor() ERC721("WrappedBeerCoin", "WBC") {

        // set up list of debtor-creditor pairs
        pairs[1] = bcPair(0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 0x7cB57B5A97eAbe94205C07890BE4c1aD31E486A8, 1, address(0), false);
        pairs[2] = bcPair(0x503CAcaA36b1e8FC97b8Dee5e07E2f29B17b3265, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[3] = bcPair(0x3530e43fCE4A27698DeCeCBff673A1D26f6068d1, 0xc97BE818F5191C83395CF360b7fb3F8054f31106, 1, address(0), false);
        pairs[4] = bcPair(0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 0xB4Bc91a35BB1D0346554F7baa29d6e87A630b2cE, 1, address(0), false);
        pairs[5] = bcPair(0x16B5bd98D638888FC92876cd6D6C446b6d307863, 0x7cB57B5A97eAbe94205C07890BE4c1aD31E486A8, 1, address(0), false);
        pairs[6] = bcPair(0xC86e32838e72E728c93296B0Ef11303B3D97a7A7, 0x7cB57B5A97eAbe94205C07890BE4c1aD31E486A8, 1, address(0), false);
        pairs[7] = bcPair(0x831CFfd303252765BA1FE15038C354D12ceBABd1, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[8] = bcPair(0x09239490B80dB265fE3120DF19967CfaAcF4463E, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[9] = bcPair(0x0a58b1C9aaF19693813c11b8a20D20C2a8Fe8883, 0xDFAEf2eeE901dde3f2f790b3D81c491D2EeEaeB4, 2, address(0), false);
        pairs[10] = bcPair(0x0EFE4959b1F91A6B60186726284D6F4d068816D5, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[11] = bcPair(0x3e782b7cd96e968B7F17d26F96d1577B3501F76F, 0xe25D09A11f351C5c4E5250A95bb023448eCbC04C, 1, address(0), false);
        pairs[12] = bcPair(0x3e782b7cd96e968B7F17d26F96d1577B3501F76F, 0xA529402B3E58b955EE7BA49FE853CfCF1bbD75fA, 1, address(0), false);
        pairs[13] = bcPair(0x3e782b7cd96e968B7F17d26F96d1577B3501F76F, 0x9C3C1F05DC5d1205C1824cfaD15307f9BF1fd72D, 1, address(0), false);
        pairs[14] = bcPair(0x5E44E1cb6F4991BEAe7C22f0177dF752169841F0, 0xC7B4F9e4932a4beb7402e20D9fb89326f0884626, 12, address(0), false);
        pairs[15] = bcPair(0x5E44E1cb6F4991BEAe7C22f0177dF752169841F0, 0x1e0F81E81Befb5Ae5B975cB0A80A48E86B9364cc, 1, address(0), false);
        pairs[16] = bcPair(0xFbDe24Ac8A2051d874a70CB18344dda8F2b54E33, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[17] = bcPair(0x63E6B51E290beEA1B6404F9D893110A6498a601E, 0xD6d5A0C02bBfFf176cCB4B3CFE12115A0ae46bde, 1, address(0), false);
        pairs[18] = bcPair(0xE8dF9A7C34736a482A861a49b51fbc1C4C031456, 0x35314B63867b3A201c838c6417c4E72EE9946F8E, 1, address(0), false);
        pairs[19] = bcPair(0x98B1658701bB6179a8Ec191f5F83fA776730Df15, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[20] = bcPair(0x98B1658701bB6179a8Ec191f5F83fA776730Df15, 0x712951253C9a5519ed199EA6F4D1a744535ec72F, 1, address(0), false);
        pairs[21] = bcPair(0x145Bc20c2Eb66aEfa7D5D49da74daAbb63c32D76, 0xD6d5A0C02bBfFf176cCB4B3CFE12115A0ae46bde, 2, address(0), false);
        pairs[22] = bcPair(0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 0xa34e7A26578BD3DF4411f45AF09E019dAd9F27c2, 1, address(0), false);
        pairs[23] = bcPair(0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 0x1daE0CEE62035444A159dd9cA3911A6A4baD77BF, 1, address(0), false);
        pairs[24] = bcPair(0x0AE14271999B68a35eEcb2Da492486e354ef672e, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[25] = bcPair(0xF7Bc5d229374470e3aDB671505c2C8a716810dC5, 0xd04e62191b27Fe60632C6999077000dAecA12881, 2, address(0), false);
        pairs[26] = bcPair(0xd674822D41520D95383e3015D3C0EE8C60f7719C, 0xd04e62191b27Fe60632C6999077000dAecA12881, 2, address(0), false);
        pairs[27] = bcPair(0x176D7673fDcB275BC3186412A922D2901068aaCA, 0x2a089726C072F5A00057373F697257CE6C492A35, 1, address(0), false);
        pairs[28] = bcPair(0xBfB21f5F2069eC2f0a3c5049DB7856a26fa5003d, 0x4bF54f201D1361833B3a2f8A1dbB702Ae0483c63, 1, address(0), false);
        pairs[29] = bcPair(0xFa6A0944543bC0536B18D05d740AF1C1d3381728, 0x607Aa83060A9B104849c643Bc305b93D757C931b, 1, address(0), false);
        pairs[30] = bcPair(0x6905CB6c44b37E13DdFE0C21643a3F4121428236, 0xABafA36e5907AD7DE32d7959877f6B68B9088847, 1, address(0), false);
        pairs[31] = bcPair(0x808aa6300acb9Dd0108e4b3E989C7523809983b4, 0x66C4F74E3EF54294ffa9e8237CC8D11d83FE497a, 1, address(0), false);
        pairs[32] = bcPair(0x58bbBeEa89189839cBBa3c1F96e43a581A5e2535, 0xa3c9a229b9749171D3ED23d790DF8AEBFE901C8e, 2, address(0), false);
        pairs[33] = bcPair(0xCEeD47cA5B899fd1623F21e9bd4DB65A10E5B09D, 0x38c7C05f8E37Eb97dDE95093f0c903C079A45fa0, 1, address(0), false);
        pairs[34] = bcPair(0x513644F3C7cC1100c7111Af894f136D0D47287D2, 0x153028dc4d8bc96aC873032843BA52Ace5E59e53, 2, address(0), false);
        pairs[35] = bcPair(0xaA5ba45127268b7E4B59058a952Ab1E926De2075, 0x4db6eEEc53885F2d66c070CC9aBB59a2DA1Ed39F, 1, address(0), false);
        pairs[36] = bcPair(0x1A2D543EA30fFb007072d2a75D7Cf9bF7e8DA616, 0x2e6DD331CF358430bcbf12306B41016AEe7781ee, 1, address(0), false);
        pairs[37] = bcPair(0xfaf3e7b0b878c9a98c023FEbebAe298eF3a9c245, 0x4dA2bF342C531407616f2bb100Daa6D6dBC54375, 1, address(0), false);
        pairs[38] = bcPair(0x167FFD913347aF05116F873C19a3fE14494aFD7b, 0x56c03A07433B771E73C19ca625232ED0d585E263, 1, address(0), false);
        pairs[39] = bcPair(0x3682Ae583f8C542ede42A9CA41105E5740B80D55, 0x49B3Bd416c1c41024d6141ACd0f366B0498cA5C8, 1, address(0), false);
        pairs[40] = bcPair(0x64b2D331b1a63846978f25070855aAFC50084ef1, 0x500e9FCee39A071c476C749BCB988C617381b8c5, 1, address(0), false);
        pairs[41] = bcPair(0xed889281648F618dd1cA9E07359BEd624B4A8790, 0xDBC1573bD5c31655b55C702406A2655BbD9dFA89, 1, address(0), false);
        pairs[42] = bcPair(0x3FF047E5E803e20f5eF55eA1029aDB89618047Db, 0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 1, address(0), false);
        pairs[43] = bcPair(0x63Cf90D3f0410092FC0fca41846f596223979195, 0x0037A6B811ffeB6e072DA21179d11B1406371C63, 1, address(0), false);
        pairs[44] = bcPair(0x63Cf90D3f0410092FC0fca41846f596223979195, 0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 1, address(0), false);
        pairs[45] = bcPair(0x63Cf90D3f0410092FC0fca41846f596223979195, 0x51d8782D82258441078E57141Daa8FFdDAf8f57D, 1, address(0), false);
        pairs[46] = bcPair(0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 0xacbb6e2b07cdABa10dbD9A484865DE69cAF5e064, 1, address(0), false);
        pairs[47] = bcPair(0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 0x5E58Caeb958e67C89ADC9e5e6bcaa79795E8d3f1, 1, address(0), false);
        pairs[48] = bcPair(0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 0xfEA7499bdEf1d8a66E8C5e3aD8014b837ceE239c, 1, address(0), false);
        pairs[49] = bcPair(0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 0x484Aa92Fa68031774140Ab9833b1615c07359b9d, 1, address(0), false);
        pairs[50] = bcPair(0xacbb6e2b07cdABa10dbD9A484865DE69cAF5e064, 0xf3946c397dbef1356e24ca6584D798d5150F521E, 1, address(0), false);
        pairs[51] = bcPair(0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 0xDbADdbaE610da85FA15A9F7e279d9A9d68B05c01, 1, address(0), false);
        pairs[52] = bcPair(0x3906842E00abf96cc58300BeC49124e6A36a46DB, 0x7632b6E235201Ec2CD8A6547ba836229101f5711, 1, address(0), false);
        pairs[53] = bcPair(0x260F180cFaa31e8A615545767461D4A0d72902E4, 0x3a7dB224aCaE17de7798797D82cdF8253017DFa8, 1, address(0), false);
        pairs[54] = bcPair(0xBe00b986EaE90D5c65e31A3C0B6136d51236d7B5, 0x4C82a81aE95A5E79750ad617CdE4beBdEe2d0536, 1, address(0), false);
        pairs[55] = bcPair(0xbfaA871Cc61533679fB74e583e2E023a920fB565, 0x244E9b38FC1c655de53A8ba5A4760F6E8001403b, 1, address(0), false);
        pairs[56] = bcPair(0x0003E8f7a763277D10AA6b6683a97C7e7890bda9, 0xD4FA839eDE2723d0F6394Fd1BE42b7A0Fd63e7c4, 1, address(0), false);
        pairs[57] = bcPair(0x7777777d56309Ea59568e5EC24c1705bDD5EcA28, 0xD0944Aa185A1337061AE20dC9dD96c83b2bA4602, 1, address(0), false);
        pairs[58] = bcPair(0x7777777d56309Ea59568e5EC24c1705bDD5EcA28, 0x7cB57B5A97eAbe94205C07890BE4c1aD31E486A8, 1, address(0), false);
        pairs[59] = bcPair(0xd1324aDA7e026211D0CacD90CAe5777E340dE948, 0x65DDc3a1f2762f3d0669bbEeA44E16B2b38090A5, 1, address(0), false);
        pairs[60] = bcPair(0xd1324aDA7e026211D0CacD90CAe5777E340dE948, 0x677748842FC14d7f4a3f6fB533ab16613C50a9B9, 1, address(0), false);
        pairs[61] = bcPair(0x00dFf2030dF1cC59Df5305597eD02F4cDF1AEdA9, 0xF4ED444467E7726741287cD8E2c97C112D17Cc36, 1, address(0), false);
        pairs[62] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0x6A3468B46eF13A96A9319C304be711aCb5dC20BE, 1, address(0), false);
        pairs[63] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0x5Dc6Fb59078789d4D185e4c1CEc9984807DB46Dd, 1, address(0), false);
        pairs[64] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0x8E46e5E47418487e6B47057249e81B1BfAda0450, 1, address(0), false);
        pairs[65] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0xF9F3beB1D3C581469b73cbEA560Aa605cA27d618, 1, address(0), false);
        pairs[66] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0x92D017aE54748f1f60dAdCCD98C3D8C24E2Bf465, 1, address(0), false);
        pairs[67] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0x071DA95DA643FE9CBdCA939D054B5bEc9cB68543, 1, address(0), false);
        pairs[68] = bcPair(0x7777777d56309Ea59568e5EC24c1705bDD5EcA28, 0xc0fFee3BD37d408910eCab316a07269FC49a20EE, 1, address(0), false);
        pairs[69] = bcPair(0xCC3d8656166d738a2B3C96Cd475405c668352989, 0x5171d344E2381424C408Ab4037C92a65F185618b, 1, address(0), false);
        pairs[70] = bcPair(0xCC3d8656166d738a2B3C96Cd475405c668352989, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[71] = bcPair(0xc0ffeebCe16ECBbb28Fc8568dB679b48e1C975F9, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[72] = bcPair(0xD0944Aa185A1337061AE20dC9dD96c83b2bA4602, 0xc0FFeEcE5397F30E18A8dd7A92644178675FBBbE, 1, address(0), false);
        pairs[73] = bcPair(0xc0fFee3BD37d408910eCab316a07269FC49a20EE, 0x88Fd7a2e9e0E616a5610B8BE5d5090DC6Bd55c25, 1, address(0), false);
        pairs[74] = bcPair(0x09aDDe38e55e4Db60A048c11e1de4f11Cc14e97b, 0x879B12C310B5C6596618B777512eaBFca98f18C3, 1, address(0), false);
        pairs[75] = bcPair(0x22F3BA469d0F91A173b1aCCeb7f211CDbde8C27B, 0xB8fc8C2f69f5C02FbdeF062f12C4875D8647A3b1, 1, address(0), false);
        pairs[76] = bcPair(0x22F3BA469d0F91A173b1aCCeb7f211CDbde8C27B, 0x00353dC8b8425298b8B6bDf587c4f5631601715C, 1, address(0), false);
        pairs[77] = bcPair(0xD88e34c9894a69b7302e2B09ac9b9c30Aa2751fC, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);

        // establish mapping from debtor-creditor pair to ID
        for (uint256 i = 1; i <= numPairs; i++) {
            indexes[pairs[i].debtor][pairs[i].creditor] = i;
        }
    }

    function Wrap(address debtor) public {
        uint256 pairId = indexes[debtor][msg.sender];  

        require(pairId != 0, "Invalid debtor-creditor pair.");
        require(!_exists(pairId), "Token already exists.");

        bcPair storage pair = pairs[pairId]; 
 
        require(!pair.wrapped, "Cannot wrap more than once.");        
        require(bcContract.allowance(msg.sender, address(this)) >= pair.numBeers, "You did not give wrapper transfer permission.");
        require(bcContract.balanceOf(msg.sender, debtor) >= pair.numBeers, "Original IOU no longer exists.");
        
        // create holder for the IOU
        BeerCoinHolder bcHolder = new BeerCoinHolder(address(this), pair.numBeers);
        pair.holderAddr = address(bcHolder);

        require(bcContract.allowance(pair.holderAddr, address(this)) >= pair.numBeers, "Holder did not give wrapper transfer permission.");
        require(bcContract.maximumCredit(pair.holderAddr) >= pair.numBeers, "Holder does not have enough credit.");
        
        // transfer IOU to the holder
        if (bcContract.transferOtherFrom(msg.sender, pair.holderAddr, debtor, pair.numBeers)) {
            _mint(msg.sender, pairId);
            pairs[pairId].wrapped = true;
            emit Wrapped(pairId, msg.sender);
        }
    }

    function Unwrap(uint256 pairId) public {
        require(_exists(pairId), "Token does not exist.");
        require(msg.sender == ownerOf(pairId), "You are not the owner.");
        
        bcPair storage pair = pairs[pairId];

        require(bcContract.maximumCredit(msg.sender) >= pair.numBeers, "You do not have enough credit.");
        
        // transfer IOU from the holder
        if (bcContract.transferOtherFrom(pair.holderAddr, msg.sender, pair.debtor, pair.numBeers)) {
            _burn(pairId);
            emit Unwrapped(pairId, msg.sender);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://spaces.beerious.io/";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "BeerCoinOrigContract.sol";


contract BeerCoinHolder {

    BeerCoinOrigContract bcContract = BeerCoinOrigContract(0x74C1E4b8caE59269ec1D85D3D4F324396048F4ac);
    
    constructor(address wrapAddr, uint256 numBeers) {
        bcContract.setMaximumCredit(numBeers);
        bcContract.approve(wrapAddr, numBeers);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface BeerCoinOrigContract {
    function maximumCredit(address owner) external returns (uint);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address owner, address debtor) external returns (uint256 balance);
    function setMaximumCredit(uint credit) external;
    function approve(address spender, uint256 value) external returns (bool);
    function transferOtherFrom(address from, address to, address debtor, uint value) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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