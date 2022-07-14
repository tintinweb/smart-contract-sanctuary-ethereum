// contracts/nftclub.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// Import Ownable from the OpenZeppelin Contracts library
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/Pausable.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

// Share configure
struct TShare {
    address owner;
    uint256 ratioPPM;
    uint256 collectAmount;      /// How much profit this user have collected
}

abstract contract ERC721AM is ERC721A {
    mapping(address => uint256[]) public tokenIDByHolder;

    // Override the _transfer function to record holders
    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);
        updateHolderInfo(from, to, tokenId);
    }

    function updateHolderInfo(address from, address to, uint256 tokenId) internal {
        // tokenIDByHolder[to].push(tokenId);
        // for (uint256 i = 0; i < tokenIDByHolder[from].length; i++) {
        //     if (tokenIDByHolder[from][i] == tokenId) {
        //         delete tokenIDByHolder[from][i];
        //         break;
        //     }
        // }
    }
}


contract ManeBase is ERC721AM, Ownable {
    // Mint price in sale period
    uint256 public _salePrice;

    // Use for tracing
    // uint256 public clubId;   // obsoleted
    //mapping(uint256 => bool) public _clubIds;
    
    address public factory;

    // // Wallet for receive mint value
    // address payable _wallet;

    // Total amount of minted (include platform fee, include refunded token)
    uint256 public mintedAmount;    // 不用了

    // Total amount of minted (not include refunded token)
    uint256 public mintedAmountNotRefunded; // 不用了

    
    uint256 public platformBalance;
    uint256 public ownerBalance;
    uint256 public collectorBalance;
    //uint256 collectorGotAmount;

    uint256 private _reserveQuantity;

    // Max number allow to mint
    uint256 public _maxSupply;
  
    // Presale and Publicsale start time
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public saleStartTime;
    uint256 public saleEndTime;

    // Presale Mintable Number
    uint256 public presaleMaxSupply = 0;
    uint256 public presaleMintedCount = 0;

    // Mint count per address
    mapping(address => uint256) public presaleMintCountByAddress;
    uint256 public presaleMaxMintCountPerAddress;

    mapping(address => uint256) public saleMintCountByAddress;
    uint256 public saleMaxMintCountPerAddress;

    

    // Platform fee ratio in PPM
    uint256 public platformFeePPM = 0;

    uint256 public isForceRefundable = 0;

    // Is the contract paused
    uint256 public paused = 0;


    event TokenMinted(address minter, uint256 tokenId , uint256 mintPrice, uint256 platformFee);
    
    event ContractDeployed(address sender, address contract_address, uint256 reserveQuantity, uint256 clubId);

    //using Strings for uint256;

    // Max token supply
    //uint256 private _totalSupply;
    //uint256 public _maxId;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Mint Information
    // mapping(tokenID => TMintInfO)
    struct TMintInfo {
        uint256 isPreMint;
        uint256 isRefunded;
        //address minter;
        uint256 price;
    }
    mapping(uint256 => TMintInfo) public _mintInfo;

    // Refund Times and Ratios
    struct TRefundTime {
        uint256 endTime;        /// Refund is available before this time (and isRefundable == true). In unix timestamp.
        uint256 ratioPPM;       /// How much ratio can be refund
    }

    
    // Share list
    TShare[] public _shareList;

    // Refund Time List    
    TRefundTime[] public _refundTimeList;

    /**
    u256[0] =>  reserveQuantity
        [1] =>  maxSupply
        [2] =>  presaleMaxSupply
        [3] =>  clubID
        [4] =>  presaleStartTime
        [5] =>  presaleEndTime
        [6] =>  saleStartTime
        [7] =>  saleEndTime
        [8] =>  presalePrice        (obsoleted)
        [9] =>  salePrice
        /// How many tokens a wallet can mint
        [10] => presalePerWalletCount
        [11] => salePerWalletCount
        [12] => signature nonce
    */ 
    constructor(string memory name_, string memory symbol_, uint256[] memory u256s,
                address[] memory shareAddresses_, uint256[] memory shareRatios_, uint256[] memory refundTimes_, uint256[] memory refundRatios_
            ) ERC721A(name_, symbol_) {   
        require(u256s[0] + u256s[2] <= u256s[1], "reserveQuantity + presaleMaxSupply must smaller or equal to maxSupply");


        // 1. Deplay and log the create event
        factory = msg.sender;

        //setSaleTimes(u256s[4], u256s[5]);
        presaleMaxSupply = u256s[2];
        //clubId = u256s[3];
        presaleStartTime = u256s[4];
        presaleEndTime = u256s[5];
        saleStartTime = u256s[6];
        saleEndTime = u256s[7];

        setMintPrice(u256s[9]);
        //setMaxSupply(u256s[1]);
        _maxSupply = u256s[1];
        //setWallet(payable(tx.origin));
        transferOwnership(tx.origin);


        emit ContractDeployed(tx.origin, address(this), u256s[0], u256s[3]);

        /// 2. Reserve tokens for creator
        initReserve(u256s[0]);

        /// 3. Setting share list
        //_shareList = new TShare[](shareAddresses_.length);
        uint256 totalShareRatios = 0;
        for (uint256 i = 0; i < shareAddresses_.length; i++) {
            TShare memory t;
            t.owner = shareAddresses_[i];
            t.ratioPPM = shareRatios_[i];
            t.collectAmount = 0;

            totalShareRatios += t.ratioPPM;

            _shareList.push(t);
        }
        require(totalShareRatios <= 1 * 1000 * 1000, "ManeBase: shareRatios overflow");

        /// 4. Setting refund times
        require(refundTimes_.length == refundRatios_.length, "ManeBase: length mismatch");
        //_refundTimeList = new TRefundTime[](refundTimes_.length);
        uint256 oldEndTime = 0;
        uint256 oldRatio = 1e9;
        for( uint256 i = 0; i < refundTimes_.length; i++) {
            TRefundTime memory t;
            t.endTime = refundTimes_[i];
            t.ratioPPM = refundRatios_[i];

            require(t.endTime > oldEndTime, "ManeBase: refundTimes invalid");
            require(t.ratioPPM < oldRatio, "ManeBase: refundRatio invalid");

            oldEndTime = t.endTime;
            oldRatio = t.ratioPPM;

            _refundTimeList.push(t);
        }
        

        /// 5. Setting mint limit for wallets
        presaleMaxMintCountPerAddress = u256s[10];
        saleMaxMintCountPerAddress = u256s[11];
        unchecked{
            if (presaleMaxMintCountPerAddress == 0) {
                presaleMaxMintCountPerAddress -= 1;
            }
            if (saleMaxMintCountPerAddress == 0) {
                saleMaxMintCountPerAddress -= 1;
            }
        }

        /// 6. Setting platform PPM
        platformFeePPM = ManeFactory(factory).platformFeePPM();
    }

    function initReserve(uint256 reserveQuantity) private {
        if (reserveQuantity > 0) {
            uint256 currentIndex = _currentIndex;
            _mint(tx.origin, reserveQuantity, "", false);
            for (uint256 i = currentIndex; i < currentIndex + reserveQuantity; i++) {
                emit TokenMinted(tx.origin, i, 0, 0);
                tokenIDByHolder[tx.origin].push(i);
            }
        }
    }


    function getAll() public view returns (uint256[] memory) {
        uint256[] memory u = new uint256[](12);
       
        u[0] = _reserveQuantity;
        u[1] = _maxSupply;
        u[2] = presaleMaxSupply;
        // u[3] = clubId;   // (obsoleted)
        u[4] = presaleStartTime;
        u[5] = presaleEndTime;
        u[6] = saleStartTime;
        u[7] = saleEndTime;
        // u[8] = 0;       // (obsoleted)
        u[9] = _salePrice;
        u[10] = presaleMaxMintCountPerAddress;
        u[11] = saleMaxMintCountPerAddress;

        return (u);
    }
    
    // Minted token will be sent to minter
    // sign_deadline, r, s, v is only require at presale perioid. These parameters are server-side signature data.
    function mint(address minter, uint256 mint_price, uint256 count, uint256 sign_deadline, bytes32 r, bytes32 s, uint8 v) payable whenNotPaused public {
        uint256 isPresale = 0;
        bool isSale = false;

        // 0. Check is mintable
        if (block.timestamp < presaleStartTime) {
            // Period: Sale not started
            revert("ManeBase: Sale not started");
        } else if (block.timestamp >= presaleStartTime && block.timestamp < presaleEndTime) {
            // Period: Pre-sale period
            require(msg.value >= mint_price * count, "ManeBase: insufficant value for presale");
            isPresale = 1;
        } else if (block.timestamp >= saleStartTime && block.timestamp <= saleEndTime) {
            // Period: Public sale perild
            require(msg.value >= _salePrice * count, "ManeBase: insufficant value for sale");
            isSale = true;
        } else {
            revert("ManeBase: Invalid _period");
        }

        /// Mint `count` number of tokens
        for (uint256 i = 0; i < count; i++) {
            require(totalMinted() < _maxSupply, "ManeBase: No more tokens");

            // uint256 expectPlatformFee = mint_price * platformFeePPM / 1e6 ;
            // uint256 userGotAmount = mint_price - expectPlatformFee;
            // uint256 actualPlatformFee = msg.value - mint_price;
            // require(actualPlatformFee >= expectPlatformFee, "ManeBase: insufficant platform fee");

            if (isPresale == 1) {
                requireMintSign(minter, mint_price, count, sign_deadline, r, s, v);

                presaleMintedCount++;
                require(presaleMintedCount <= presaleMaxSupply, "ManeBase: Cant mint more for presale");
                
                presaleMintCountByAddress[msg.sender]++;
                require(presaleMintCountByAddress[msg.sender] <= presaleMaxMintCountPerAddress, "ManeBase: addr limit exceed(A)");
            } else if (isSale == true) {
                //requireMintSign(minter, mint_price, sign_deadline, r, s, v);

                saleMintCountByAddress[msg.sender]++;
                require(saleMintCountByAddress[msg.sender] <= saleMaxMintCountPerAddress, "ManeBase: addr limit exceed(B)");
                
            } else {
                revert("ManeBase: Not sale period");
            }


            // 1. Mint it
            uint256 currentIndex = _currentIndex;

            _mint(minter, 1, "", false);
            tokenIDByHolder[minter].push(currentIndex);


            // 2. Send mint value to creator and platform and collectors
            //ManeFactory(factory).wallet().transfer(expectPlatformFee);
            //_wallet.transfer(mint_price);
            uint256 platformGot = mint_price * platformFeePPM / 1e6;
            uint256 collectorGot = (mint_price - platformGot) * getCollectorTotalRatioPPM() / 1e6;
            uint256 ownerGot = mint_price - platformGot - collectorGot;
            
            platformBalance += platformGot;
            collectorBalance += collectorGot;
            //collectorGotAmount += collectorGot;
            ownerBalance += ownerGot;
            
            // 3. Do stats
            mintedAmount = mintedAmount + mint_price;
            mintedAmountNotRefunded = mintedAmountNotRefunded + mint_price;
            

            // 4. Log events and other data
            _mintInfo[currentIndex] = TMintInfo({
                isPreMint: isPresale,
                isRefunded: 0,
                //minter: minter,
                price: mint_price
            });

            emit TokenMinted(minter, currentIndex, mint_price, platformGot);
        }
        
        //  Mint finished successfully
    }


    /// User request to refund
    function refund(uint256 tokenID) public {
        require(msg.sender == ownerOf(tokenID), "ManeBase: Not owner");
        
        /// 1. Get refund ratio
        // If forceRefundable is true, holder can refund all. Otherwise holder can only refund before refund time
        uint256 refundRatioPPM = 1e6;
        if (isForceRefundable == 0) {
            for (uint256 i = 0; i < _refundTimeList.length; i++) {
                if (block.timestamp < _refundTimeList[i].endTime) {
                    refundRatioPPM = _refundTimeList[i].ratioPPM;
                    break;
                }
            }
        }
        require(refundRatioPPM > 0, "ManeBase: refund not avail");

        /// 2. Get mint info and check if this token is refundable
        TMintInfo storage mintInfo = _mintInfo[tokenID];
        
        require(mintInfo.isRefunded == 0, "ManeBase: already refunded");

        /// 3. Caculate the refundable value
        uint256 refundValue = mintInfo.price * refundRatioPPM / 1e6; 

        /// 4. Do refund
        mintedAmount -= refundValue;

        uint256 platformReturn = refundValue * platformFeePPM / 1e6;
        uint256 collectorReturn = (refundValue - platformReturn) * getCollectorTotalRatioPPM() / 1e6;
        uint256 ownerReturn = refundValue - platformReturn - collectorReturn;

        platformBalance -= platformReturn;
        collectorBalance -= collectorReturn;
        //collectorGotAmount -= collectorReturn;
        ownerBalance -= ownerReturn;
        

        transferFrom(msg.sender, this.owner(), tokenID);
        
        mintInfo.isRefunded = 1;

        payable(msg.sender).transfer(refundValue);
    }


    // Send shares to share holders and owner
    function collect() public onlyOwner {
        /// 1. Check if collect is open
        requireCollectable();        

        /// 2. Find the collector and transfer
        uint256 b = collectorBalance;
        uint256 totalRatioPPM = getCollectorTotalRatioPPM();
        for (uint256 i = 0; i < _shareList.length; i++) {
            //uint256 collectValue = b * _shareList[i].ratioPPM * / 1e6;
            uint256 collectValue = b * _shareList[i].ratioPPM / totalRatioPPM;
            collectorBalance -= collectValue;
            payable(_shareList[i].owner).transfer(collectValue);
        }

        /// 3. send balance to owner
        uint256 oBalance = ownerBalance;
        ownerBalance = 0;
        payable(owner()).transfer(oBalance);
    }


    // Platform (ManeStudio) collect it's shares
    function platformCollect(address to) public {
        requireCollectable();

        uint256 b = platformBalance;
        //payable(ManeFactory(factory).wallet()).transfer(b);
        payable(to).transfer(b);
        platformBalance = 0;
    }

    function requireCollectable() view internal {
        for (uint256 i = 0; i < _refundTimeList.length; i++) {
            require(block.timestamp > _refundTimeList[i].endTime, "ManeBase: Can't collect before refund deadline");
        }
    }
    
    /// If signagure is not valid, throw exception and stop
    function requireMintSign(address minter, uint256 price, uint256 count, uint256 deadline, bytes32 r, bytes32 s, uint8 v)  internal view {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 userHash = encodeMint(minter, price, count, deadline);
        bytes32 prefixHash = keccak256(abi.encodePacked(prefix, userHash));

        address hash_address = ecrecover(prefixHash, v, r, s);

        //require(msg.sender == minter, "ManeBase: Invalid sender in signature");

        //require(hash_address == owner(), "ManeBase: Invalid signature");
        require(hash_address == ManeFactory(factory).signerAddress(), "ManeBase: Invalid sign");
    }


    function encodeMint( address minter, uint256 price, uint256 count, uint256 deadline) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(minter, price, count, deadline));
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    // function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
    //     require(newMaxSupply >= totalMinted(), "ManeBase: maxSupply too small");
    //     _maxSupply = newMaxSupply;
    // }

    function _baseURI() override internal view returns (string memory) {
        string memory factoryBaseURI = ManeFactory(factory).factoryBaseURI();
        return string(abi.encodePacked(factoryBaseURI, toString(abi.encodePacked(this)), "/"));
    }
    
    // Set the mint price for sale period
    function setMintPrice(uint256 sale_price) public onlyOwner {
        _salePrice = sale_price;
    }

    function setPresaleMaxSupply(uint256 max_) public onlyOwner {
        presaleMaxSupply = max_;
    }
    

    // function setSaleTimes(uint256 preSaleStartTime_, uint256 saleStartTime_) private onlyOwner {
    //     require(preSaleStartTime_ <= saleStartTime_, "ManeBase: preSaleStartTime must be smaller than saleStartTime");
    //     presaleStartTime = preSaleStartTime_;
    //     saleStartTime = saleStartTime_;
    // }

    // function setSaleTimesAndRefundEndTime(uint256 preSaleStartTime_, uint256 saleStartTime_, uint256 refundEndTime_) public onlyOwner {
    //     setSaleTimes(preSaleStartTime_, saleStartTime_);
    //     refundEndTime = refundEndTime_;
    // }

    function adminSetRefund(uint256 is_refundable_) public onlyFactoryOwner {
        isForceRefundable = is_refundable_;
    }


    // Set a new totalSupply
    // function setTotalSupply(uint256 newTotalSupply) public onlyOwner {
    //     _totalSupply = newTotalSupply;
    // }


    function setPresaleMaxMintCountPerAddress(uint256 max_) public onlyOwner {
        presaleMaxMintCountPerAddress = max_;
    }
    function setSaleMaxMintCountPerAddress(uint256 max_) public onlyOwner {
        saleMaxMintCountPerAddress = max_;
    }

    function getCollectorTotalRatioPPM() internal view returns (uint256) {
        uint256 ratioPPM = 0;
        for (uint256 i =0; i < _shareList.length; i++) {
            ratioPPM += _shareList[i].ratioPPM;
        }

        require(ratioPPM <= 1e6, "ManeBase: ratio overflow");

        return ratioPPM;
    }

    // Get the available amount of the mes.sender
    // If msg.sender is not in collector list, this function returns 0.
    // Otherwise this functinos returns how much amount the msg.sender can collect at the moment.
    // function availableCollectAmount(address collectAddr) view public returns (uint256) {
    //     TShare memory collector;
    //     address addr = address(0);

    //     for (uint256 i = 0; i < _shareList.length; i++) {
    //         if (collectAddr == _shareList[i].owner) {
    //             addr = collectAddr;
    //             collector = _shareList[i];
    //             break;
    //         }
    //     }

    //     if (addr == address(0)) {
    //         return 0;
    //     }

    //     uint256 maxAmount = collector.ratioPPM * mintedAmount / 1000 / 1000;

    //     return maxAmount - collector.collectAmount;
    // }

    function setPresaleTimes(uint256 startTime_, uint256 endTime_) public onlyOwner {
        presaleStartTime = startTime_;
        if (endTime_ == 0) {
            unchecked {
                presaleEndTime = endTime_ - 1;
            }
        } else {
            presaleEndTime = endTime_;
        }
    }

    function setSaleTimes(uint256 startTime_, uint256 endTime_) public onlyOwner {
        saleStartTime = startTime_;
        if (endTime_ == 0) {
            unchecked {
                saleEndTime = endTime_ - 1;
            }
        } else {
            saleEndTime = endTime_;
        }
    }





    // Get the token id list of the given address. If the address holds no token, empty array is return
    function getTokenIDsByHolder(address holder, uint256 offset, uint256 limit) public view returns (uint256[] memory) {
        uint256 size = tokenIDByHolder[holder].length - offset;
        if (size > limit) {
            size = limit;
        }
        uint256[] memory ret = new uint256[](size);

        for (uint256 i = 0; i < limit; i++) {
            if (i + offset >= tokenIDByHolder[holder].length) {
                break;
            } 
            ret[i] = (tokenIDByHolder[holder][i + offset]);
        }

        return ret;
    }


    function getShareListLength() public view returns (uint256) {
        return _shareList.length;
    }

    function getRefundTimeListLength() public view returns (uint256) {
        return _refundTimeList.length;
    }

    function setPaused(uint256 is_pause) public onlyOwner {
        paused = is_pause;
    }

    function destroy() public onlyOwner {
        require(mintedAmount == 0, "ManeBase: not allow after mint");
        selfdestruct(payable(this.owner()));
    }

    modifier onlyFactoryOwner() {
        ManeFactory(factory).requireOwner();
        _;
    }

    modifier whenNotPaused() {
        require(paused == 0, "ManeBase: paused");
        _;
    }
}


contract SignAndOwnable is Ownable { 
    address public signerAddress;

    constructor() Ownable() {
        signerAddress = tx.origin;
    }

    // Check if the signature is valid. Returns true if signagure is valid, otherwise returns false.
    function verifySignature(bytes32 h, uint8 v, bytes32 r, bytes32 s) view public returns (bool) {
        return (ecrecover(h, v, r, s) == signerAddress);
    }

    // Set the derived address of the public key of the signer private key
    function setSignaturePublic(address newAddress) public onlyOwner {
        signerAddress = newAddress;
    }
}


contract ManeFactory is SignAndOwnable {
    uint256 public platformFeePPM = 120 * 1e3;

    //address[] public contracts;

    //address payable public wallet;

    string public factoryBaseURI = "https://api.manestudio.com/nft/";

    mapping(uint256 => bool) private _usedNonces;

    // Mapping club_id => token_contract_address
    mapping(uint256 => address) public clubMap;

    constructor() SignAndOwnable() {
        //wallet = payable(msg.sender);
    }

    function deploy(string memory name_, string memory symbol_,  uint256[] memory u256s, address[] memory shareAddresses_, uint256[] memory shareRatios_, uint256[] memory refundEndTimes_, uint256[] memory refundRatios_, uint8 v, bytes32 r, bytes32 s) public returns (address) {
        /// 1. Check signagure
        bytes memory ethereum_prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 user_hash =keccak256(abi.encodePacked(ethereum_prefix, keccak256(abi.encodePacked(u256s[3], u256s[12]))));

        require(_usedNonces[u256s[12]] == false, "ManeFactory: dup nonce");
        _usedNonces[u256s[12]] = true;

        require(verifySignature(user_hash, v, r, s) == true, "ManeFactory: Invalid signature");
        
        /// 2. Deploy contract
        ManeBase c = new ManeBase(name_, symbol_, u256s, shareAddresses_, shareRatios_, refundEndTimes_, refundRatios_);
        //contracts.push(address(c));
        clubMap[u256s[3]] = address(c);


        return address(c);
    }

    function setPlatformFeePPM(uint256 newFeePPM) public onlyOwner {
        platformFeePPM = newFeePPM;
    }

    /// Set the factoryBaseURI, must include trailing slashes
    function setFactoryBaseURI(string memory newBaseURI) public onlyOwner {
        factoryBaseURI = newBaseURI;
    }

    // function setWallet(address payable newWallet) public onlyOwner {
    //     wallet = newWallet;
    // }


    function requireOwner() public onlyOwner {
    }
}

function toString(bytes memory data) pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
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
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
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