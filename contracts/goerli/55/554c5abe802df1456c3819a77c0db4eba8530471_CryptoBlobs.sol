/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}
interface IReverseRecords {
    function getNames(address[] calldata addresses) external view returns (string[] memory r);
}
abstract contract Ownable {

    constructor() {
        _contractOwner = tx.origin;

        emit OwnershipTransferred( 
            address(0),            
            _contractOwner         
        );
    }
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed approvedOwner
    );
    address internal _contractOwner;
    address internal _contractCandidate;
    uint96 internal _unused = 0;
    function owner() public view virtual returns (address) {
        return _contractOwner;
    }
    function candidate() public view virtual returns (address) {
        return _contractCandidate;
    }
}
abstract contract SuperERC721 is
    Ownable,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{

    constructor() {
        _reentrancyStatus = _reentrancyUnlocked;
        address[9] memory _preapprovedServices = [
            0x1E0049783F008A0085193E00003D00cd54003c71,
            0xF849de01B080aDC3A814FaBE1E2087475cF2E354,
            0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e,
            0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be,
            0xDef1C0ded9bec7F1a1670819833240f027b25EfF,
            0x20F780A973856B93f63670377900C1d2a50a77c4,
            0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329,
            0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d,
            0x657E383EdB9A7407E468acBCc9Fe4C9730c7C275
        ];
        for (uint256 i; i < _preapprovedServices.length; i++) {
            _account[_preapprovedServices[i]].preapprovedStatus = 2;
        }
    }

    modifier nonReentrant() {
        if (_reentrancyStatus == _reentrancyLocked) revert REENTRANT_CALLS_ARE_NOT_ALLOWED();
        _reentrancyStatus = _reentrancyLocked;
        _;
        _reentrancyStatus = _reentrancyUnlocked;
    }
    event MintPurchase(
        address account,
        address referrer,
        uint256 data
    );
    event MintFree(
        address account, 
        address contractAddress, 
        uint256 tokenId,
        uint256 data
    );
    event Trade(
        bytes32 indexed hash,
        address indexed maker,
        address indexed taker,
        uint256[] makerIds,
        uint256[] takerIds,
        uint256 price,
        uint256 expiry,
        uint256 timestamp,
        bool isTrade
    );
    event Optimize(
        address indexed account,
        uint256[] tokenIds,
        uint256 timestamp
    );
    event Metadata(
        address indexed account,
        string indexed table,
        string indexed key,
        string value,
        uint256 timestamp
    );

    string internal constant _symbol = "TEST";
    uint256 internal constant _maxSupply = 25000;
    uint256 internal constant _giveawayEnds = 10000;
    uint256 internal constant _sacrificeAndDailyDropsOffersEnds = 20000;
    uint256 internal constant _referralProgramEnds = 25000;
    uint256 internal constant _purchaseLimit = 500;
    uint256 internal constant _maxFreePerAccount = 10;
    uint256 internal constant _nftsPerCollectionLimit = 10;
    uint256 internal constant _basePriceIncrementPerPoint = 0.0000000000025 ether;
    uint256 internal constant _declineDuration = 100 hours;
    uint256 internal constant _bogoDuration = 450 seconds;
    uint256 internal constant _bogoStartingFrom = 5;
    uint256 internal constant _burnsPerReward = 10;
    uint256 internal constant _referralsPerReward = 5;
    uint256 internal constant _dailyDropThreshold = 5;
    uint256 internal constant _sections = 8;
    uint256 internal constant _distance = 3125;
    uint256 internal constant _dailyDropDuration = 10 minutes;
    uint256 internal constant _volatilityBase = 10;
    uint256 internal constant _volatilityMultiplier = 3;
    uint256 internal constant _increasedVolatilityThreshold = 20000;
    uint32 internal constant _reentrancyUnlocked = 1;
    uint32 internal constant _reentrancyLocked = 2;
    uint32 internal _reentrancyStatus;
    uint32 internal _tokensMintedPurchase;
    uint32 internal _tokensMintedFree;
    uint32 internal _tokensBurned;
    uint32 internal _temporaryDemandMultiplier;
    uint32 internal _purchaseTimestamp;
    mapping(address => uint256[]) internal _nftsRedeemed;
    mapping(address => Account) internal _account;
    mapping(uint256 => Token) internal _token;
    string internal _name = "Test";
    bool internal _tradingPaused;
    bool internal _sacrificingPaused;
    uint256 internal _URIMaxSoulsLimit = 100;
    address internal _reverseRecordsAddress = 0x333Fc8f550043f239a2CF79aEd5e9cF4A20Eb41e;
    string internal _contractURI;
    string internal _tokenURIPrefix;
    mapping(uint256 => string) internal _tokenURIPrefixes;
    struct Account {
        uint16 tokensOwned;
        uint16 mintedPurchase;
        uint8 mintedBogos;
        uint8 mintedGiveaway;
        uint16 tokensBurned;
        uint8 mintedDailyDrops;
        uint8 mintedSacrifices;
        uint8 mintedReferrals;
        uint8 mintedSpecial;
        uint16 tokensOptimized;
        uint16 referralPurchases;
        uint32 timestampDailyDropLastClaimed;
        uint32 timestampReferralLinkUsed;
        uint32 timestampTradesLocked;
        mapping(bytes32 => uint256) timestampTradeHashUsed;
        mapping(address => uint256) approvals;
        uint256 preapprovedStatus;
    }
    struct Token {
        uint32 mintTimestamp;
        uint32 burnTimestamp;
        uint16 souls;
        uint16 burnTo;
        address account;
        address approval;
    }
    struct BatchData {
        uint256 category;
        address account1;
        address account2;
        uint256 tokenId;
        uint256[] tokenIds;
        bool approved;
        bytes32 hash;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId ||         
            interfaceId == type(IERC721).interfaceId ||            
            interfaceId == type(IERC721Metadata).interfaceId ||    
            interfaceId == type(IERC721Enumerable).interfaceId;    
    }
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        unchecked {
            uint256 tokensMinted = _tokensMinted();
            uint256 indexOfOwner;
            address accountOfToken;
            uint256 balance = balanceOf(owner);
            if (index < balance) {
                for (uint256 i; i < tokensMinted; i++) {
                    uint256 tokenId = _getTokenId(i);
                    if (_token[tokenId].account != address(0)) {
                        accountOfToken = _token[tokenId].account;
                    }
                    if (accountOfToken == owner && !_isTokenSacrificed(tokenId)) {
                        if (indexOfOwner != index) {
                            indexOfOwner++;
                        } else {
                            return tokenId;
                        }
                    }
                }
            }
            revert OWNERS_BALANCE_IS_INSUFFICENT_FOR_THE_INDEX();
        }
    }
    function totalSupply() public view virtual override returns (uint256) {
        unchecked {
            return _tokensMinted() - _tokensBurned;
        }
    }
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        unchecked {
            uint256 tokensMinted = _tokensMinted();
            uint256 tokenIdsIndex;
            if (index < tokensMinted) {
                for (uint256 i; i < tokensMinted; i++) {
                    uint256 tokenId = _getTokenId(i);
                    if (!_isTokenSacrificed(tokenId)) {
                        if (tokenIdsIndex != index) {
                            tokenIdsIndex++;
                        } else {
                            return tokenId;
                        }
                    }
                }
            }
            revert INVALID_CRYPTOBLOB_ID();
        }
    }
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert THE_ZERO_ADDRESS_CANNOT_HAVE_AN_ACCOUNT();
        return _account[owner].tokensOwned;
    }
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        unchecked {
            _revertIfTokenIsInvalid(tokenId);
            uint256 index = _getTokenIndex(tokenId);
            while (true) {
                if (_token[tokenId].account == address(0)) {
                    tokenId = _getTokenId(--index);
                } else {
                    return _token[tokenId].account;
                }
            }
            revert INVALID_CRYPTOBLOB_ID();
        }
    }
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        unchecked {
            if (_getTokenIndex(tokenId) >= _tokensMinted()) revert INVALID_CRYPTOBLOB_ID();

            uint256 souls;
            if (!_isTokenSacrificed(tokenId)) souls = _token[tokenId].souls + 1;
            if (souls > _URIMaxSoulsLimit) souls = _URIMaxSoulsLimit;

            if (bytes(_tokenURIPrefix).length > 0) {
                return string(abi.encodePacked(_tokenURIPrefix, _toPaddedString(souls), "/", _toPaddedString(tokenId)));
            } else if (bytes(_tokenURIPrefixes[souls]).length > 0) {
                return string(abi.encodePacked(_tokenURIPrefixes[souls], _toPaddedString(tokenId)));
            } else {
                return "";
            }
        }
    }
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        _revertIfTokenIsInvalid(tokenId);
        return _token[tokenId].approval;
    }
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
       

        uint256 status = _account[owner].approvals[operator];
        return (
                    status == 2 ||
                    (
                        status == 0 &&
                        _account[operator].preapprovedStatus == 2 &&
                        owner != operator
                    )
                );
    }
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    function generalData(address contractAddress, uint256 tokenId) 
        public 
        view 
        returns (
            uint256[12] memory data, 
            address owner, 
            bool isERC721, 
            uint256[] memory nftsRedeemed
        ) 
    {
        unchecked {

            uint256 tokensMinted = _tokensMinted();
            data[0] = _tokensMintedPurchase;
            data[1] = _tokensMintedFree;
            data[2] = _tokensBurned;
            data[3] = block.timestamp;
            if (tokensMinted < _sacrificeAndDailyDropsOffersEnds) data[4] = _dailyDropDuration - (block.timestamp % _dailyDropDuration);
            if (_tradingPaused) data[5] = 1;
            if (_sacrificingPaused) data[6] = 1;
            if (tokensMinted != _maxSupply) (data[7], data[8], data[9], data[10], data[11]) = _marketPrice(data[0], data[1]);
            if (contractAddress != address(0)) (owner, isERC721, nftsRedeemed) = _checkNFT(contractAddress, tokenId);

            return (data, owner, isERC721, nftsRedeemed);
        }
    }
    function _checkNFT(address contractAddress, uint256 tokenId) internal view returns (address owner, bool isERC721, uint256[] memory nftsRedeemed) {
        if (_isContractPastConstruction(contractAddress)) {
            try IERC721(contractAddress).ownerOf(tokenId) returns (address _owner) { owner = _owner; } catch {}
            try IERC165(contractAddress).supportsInterface(type(IERC721).interfaceId) returns (bool _isERC721) { isERC721 = _isERC721; } catch {}
            nftsRedeemed = _nftsRedeemed[contractAddress];
        }
        return (owner, isERC721, nftsRedeemed);
    }
    function _redeemNFT(address contractAddress, uint256 tokenId) internal returns (bool redeemed) {
        unchecked {
            (address owner, bool isERC721, uint256[] memory nftsRedeemed) = _checkNFT(contractAddress, tokenId);
            if (owner != msg.sender || !isERC721 || nftsRedeemed.length >= _nftsPerCollectionLimit) revert NFT_IS_NOT_ELIGIBLE();
            for (uint256 i; i < nftsRedeemed.length; i++) {
                if (nftsRedeemed[i] == tokenId) revert NFT_IS_NOT_ELIGIBLE();
            }
            _nftsRedeemed[contractAddress].push(tokenId);

            return true;
        }
    }
    function accountData(address account, bool getENS, bool getTokens)
        public
        view
        returns (
            uint256[22] memory data,
            string memory ensName,
            uint256[] memory ownedData,
            uint256[] memory burnedData
        )
    {
        unchecked {
            data[0] = balanceOf(account);
            data[1] = _account[account].tokensBurned;
            data[2] = _account[account].tokensOptimized;
           
            data[3] = _account[account].mintedPurchase;
            data[4] = _account[account].mintedSpecial;
           
            data[6] = _account[account].mintedBogos;
            data[7] = _account[account].mintedDailyDrops;
            data[8] = _account[account].mintedSacrifices;
            data[9] = _account[account].mintedReferrals;
            data[10] = _account[account].mintedGiveaway;
            (data[5], data[12], data[13], data[14], data[15]) = _accountToClaimable(account);
            data[11] = data[12] + data[13] + data[14] + data[15];
            data[16] = _account[account].referralPurchases;
            data[17] = _account[account].timestampDailyDropLastClaimed;
            data[18] = _account[account].timestampReferralLinkUsed;
            data[19] = _account[account].timestampTradesLocked;
            if (_isContractPastConstruction(account)) data[20] = 1;
            data[21] = address(account).balance;
            if (getENS) {
                address[] memory addresses = new address[](1);
                addresses[0] = account;
                ensName = addressesToENS(addresses)[0];
            }
            if (getTokens) {

                uint256[4] memory variables;
               
               
                if (data[0] + data[1] > 0) {
                    uint256 ownedDataAmount = 4;
                    ownedData = new uint256[](data[0] * ownedDataAmount);
                   
                   

                    uint256 burnedDataAmount = 5;
                    burnedData = new uint256[](data[1] * burnedDataAmount);
                   
                   
                   
                    address accountOfToken;
                    while (data[0] + data[1] != variables[0] + variables[1]) {
                        uint256 tokenId = _getTokenId(variables[2]++);
                        if (_token[tokenId].account != address(0)) {
                            accountOfToken = _token[tokenId].account;
                        }
                        if (_token[tokenId].mintTimestamp != 0) {
                            variables[3] = _token[tokenId].mintTimestamp;
                        }
                        if (accountOfToken == account) {
                            if (!_isTokenSacrificed(tokenId)) {
                                ownedData[variables[0] * ownedDataAmount] = tokenId;
                                ownedData[(variables[0] * ownedDataAmount) + 1] = _token[tokenId].souls + 1;
                                ownedData[(variables[0] * ownedDataAmount) + 2] = variables[3];
                                ownedData[(variables[0] * ownedDataAmount) + 3] = uint160(_token[tokenId].approval);
                                variables[0]++;
                            } else {
                                burnedData[variables[1] * burnedDataAmount] = tokenId;
                                burnedData[(variables[1] * burnedDataAmount) + 1] = _token[tokenId].burnTo;
                                burnedData[(variables[1] * burnedDataAmount) + 2] = _token[tokenId].souls;
                                burnedData[(variables[1] * burnedDataAmount) + 3] = variables[3];
                                burnedData[(variables[1] * burnedDataAmount) + 4] = _token[tokenId].burnTimestamp;
                                variables[1]++;
                            }
                        }
                    }
                }
            }
            return (data, ensName, ownedData, burnedData);
        }
    }
    function accountDataByCategory(address[] memory accounts, uint256 category)
        external
        view
        returns (uint256[] memory data)
    {
        unchecked {
           
           
           
           
           
           
           
           

            uint256 accountsAmount = accounts.length;
            if (category == 0) {
               
                uint256 amount = 4;
                data = new uint256[](accountsAmount * amount);
                for (uint256 i; i < accountsAmount; i++) {
                    data[i * amount] = balanceOf(accounts[i]);
                    data[i * amount + 1] = _account[accounts[i]].tokensBurned;
                    data[i * amount + 2] = _account[accounts[i]].tokensOptimized;
                    data[i * amount + 3] = _account[accounts[i]].mintedPurchase;
                }
            } else if (category == 1) {
               
                uint256 amount = 3;
                data = new uint256[](accountsAmount * amount);
                for (uint256 i; i < accountsAmount; i++) {
                    data[i * amount] = balanceOf(accounts[i]);
                    data[i * amount + 1] = _account[accounts[i]].tokensBurned;
                    data[i * amount + 2] = _account[accounts[i]].tokensOptimized;
                }
            } else if (category == 2) {
                data = new uint256[](accountsAmount);
                for (uint256 i; i < accountsAmount; i++) {
                    (
                        ,
                        uint256 claimableDailyDrops, 
                        uint256 claimableSacrifices, 
                        uint256 claimableReferrals, 
                        uint256 claimableGiveaway
                    ) = _accountToClaimable(accounts[i]);
                    data[i] = claimableDailyDrops + claimableSacrifices + claimableReferrals + claimableGiveaway;
                }
            } else if (category == 3) {
                data = new uint256[](accountsAmount);
                for (uint256 i; i < accountsAmount; i++) {
                    data[i] = _account[accounts[i]].timestampTradesLocked;
                }
            } else {
                uint256 amount = 2;
                data = new uint256[](accountsAmount * amount);
                for (uint256 i; i < accountsAmount; i++) {
                    data[i * amount] = address(accounts[i]).balance;
                    if (_isContractPastConstruction(accounts[i])) data[i * amount + 1] = 1;
                }
            }
            return data;
        }
    }
    function addressesToENS(address[] memory accounts) public view returns (string[] memory ensNames) {
        return IReverseRecords(_reverseRecordsAddress).getNames(accounts);
    }
    function tokenData(uint256 tokenId, bool getENS)
        external
        view
        returns (
            address owner,
            address approval,
            address burner,
            uint256 mintTimestamp,
            uint256 burnTimestamp,
            uint256 ownedSouls,
            uint256 burnSouls,
            uint256 burnTo,
            uint256 distance,
            string[] memory ensNames
        )
    {
        unchecked {
            if (!_isTokenSacrificed(tokenId)) {
                owner = ownerOf(tokenId);
                approval = _token[tokenId].approval;
                ownedSouls = _token[tokenId].souls + 1;
            } else {
                burner = _token[tokenId].account;
                burnTimestamp = _token[tokenId].burnTimestamp;
                burnTo = _token[tokenId].burnTo;
                burnSouls = _token[tokenId].souls;
            }
            uint256 index = _getTokenIndex(tokenId);
            while (mintTimestamp == 0) {
                if (_token[tokenId].mintTimestamp == 0) {
                    if (_token[tokenId].account == address(0)) {
                        distance++;
                    }
                    tokenId = _getTokenId(--index);
                } else {
                    mintTimestamp = _token[tokenId].mintTimestamp;
                }
            }
            if (getENS) {
                address[] memory addresses = new address[](3);
                addresses[0] = owner;
                addresses[1] = approval;
                addresses[2] = burner;
                ensNames = addressesToENS(addresses);
            }
            return (
                owner,
                approval,
                burner,
                mintTimestamp,
                burnTimestamp,
                ownedSouls,
                burnSouls,
                burnTo,
                distance,
                ensNames
            );
        }
    }
    function tokenDataByCategory(uint256 category, uint256 index, uint256 amount)
        external
        view
        returns (uint256[] memory data)
    {
        unchecked {
            uint256 tokensMinted = _tokensMinted();
            uint256 toIndex;
            uint256 fromIndex;
            if (amount == 0) {
                amount = _maxSupply;
                toIndex = tokensMinted;
            } else {
                if (category == 0 || category == 3 || category == 8) {
                    uint maxPrecheck = _purchaseLimit + _maxFreePerAccount;
                    if (index > maxPrecheck) {
                        toIndex = maxPrecheck;
                    } else if (index != 0) {
                        toIndex = index % (maxPrecheck);
                    }
                }
                fromIndex = index - toIndex;
                toIndex += fromIndex + amount;
                if (toIndex > tokensMinted) {
                    toIndex = tokensMinted;
                    amount = toIndex - index;
                }
            }
            data = new uint256[](amount);
            uint256 holdNumber;
            if (category != 8) {
                while (fromIndex < toIndex) {
                    uint256 tokenId = _getTokenId(fromIndex);
                    bool sacrificed = _isTokenSacrificed(tokenId);
                    uint256 dataRetrieved;
                    if (category == 0) {
                        if (_token[tokenId].account != address(0)) {
                            holdNumber = uint160(_token[tokenId].account);
                        }
                        if (!sacrificed) {
                            dataRetrieved = holdNumber;
                        }
                    } else if (category == 1) {
                        dataRetrieved = uint160(_token[tokenId].approval);
                    } else if (category == 2) {
                        if (_token[tokenId].account != address(0)) {
                            holdNumber = uint160(_token[tokenId].account);
                        }
                        if (sacrificed) {
                            dataRetrieved = holdNumber;
                        }
                    } else if (category == 3) {
                        if (_token[tokenId].mintTimestamp != 0) {
                            holdNumber = _token[tokenId].mintTimestamp;
                        }
                        dataRetrieved = holdNumber;
                    } else if (category == 4) {
                        dataRetrieved = _token[tokenId].burnTimestamp;
                    } else if (category == 5 && !sacrificed) {
                        dataRetrieved = _token[tokenId].souls + 1;
                    } else if (category == 6 && sacrificed) {
                        dataRetrieved = _token[tokenId].souls;
                    } else if (category == 7 && sacrificed) {
                        dataRetrieved = _token[tokenId].burnTo;
                    }
                    if (amount == _maxSupply) {
                        if (dataRetrieved != 0) {
                            data[tokenId - 1] = dataRetrieved;
                        }
                    } else if (fromIndex >= index) {
                        if (dataRetrieved != 0) {
                            data[fromIndex - index] = dataRetrieved;
                        }
                    }
                    fromIndex++;
                }
            } else if (category == 8) {
                uint256 tokensChecked;
                while (fromIndex < toIndex) {
                    if (_token[_getTokenId(toIndex - tokensChecked - 1)].account == address(0)) {
                        holdNumber++;
                    } else if (holdNumber > 0) {
                        for (uint256 j; j < holdNumber + 1; j++) {
                            if (amount == _maxSupply) {
                                data[_getTokenId(toIndex - tokensChecked - 1 + j) - 1] = j;
                            } else if (toIndex - tokensChecked - 1 + j >= index) {
                                data[toIndex - tokensChecked - 1 + j - index] = j;
                            }
                        }
                        delete holdNumber;
                    }
                    tokensChecked++;
                    fromIndex++;
                }
            }
            return data;
        }
    }
    function isTradeApprovedAndValid(
        address maker,
        address taker,
        uint256[] memory makerIds,
        uint256[] memory takerIds,
        uint256 price,
        uint256 expiry,
        uint256 salt,
        bytes memory signature,
        bool checkAccess
    )
        public
        view
        returns (
            bytes32 hash,
            uint256[8] memory errors
        )
    {
        unchecked {
            hash = keccak256(
                abi.encode(
                    address(this),
                    maker,
                    taker,
                    keccak256(abi.encode(makerIds)),
                    keccak256(abi.encode(takerIds)),
                    price,
                    expiry,
                    salt
                )
            );
            if (!_isTradeApproved(maker, hash, signature)) errors[0] = 1;
            if (maker == address(0)) errors[1] = 1;
            errors[2] = _account[maker].timestampTradesLocked;
            errors[3] = _account[maker].timestampTradeHashUsed[hash];
            if (expiry <= block.timestamp && expiry != 0) errors[4] = 1;
            if (taker == address(0) && takerIds.length > 0) errors[5] = 1;
           
            if (checkAccess) {
                for (uint256 i; i < makerIds.length; i++) {
                    (bool hasAccess,) = _hasAccess(maker, makerIds[i]);
                    if (!hasAccess) errors[6]++;
                }
                for (uint256 i; i < takerIds.length; i++) {
                    (bool hasAccess,) = _hasAccess(taker, takerIds[i]);
                    if (!hasAccess) errors[7]++;
                }
            }

            return (hash, errors);
        }
    }
    function batchTradeHashUsedAndHasAccess(
        address[] memory accounts,
        uint256[] memory numbers
    ) 
        external
        view
        returns (
            uint256[] memory data
        )
    {
        uint256 maxSupply = _maxSupply;
        uint256 accountsAmount = accounts.length;
        data = new uint256[](accountsAmount);
        for (uint256 i; i < accountsAmount; i++) {
            if (numbers[i] > maxSupply) {
                data[i] = _account[accounts[i]].timestampTradeHashUsed[bytes32(numbers[i])];
            } else {
                bool hasAccess;
                (hasAccess,) = _hasAccess(accounts[i], numbers[i]);
                if (hasAccess) data[i] = 1;
            }
        }
        return data;
    }
    function preapprovedServiceStatus(address account) external view returns (uint256 status) {
        return _account[account].preapprovedStatus;
    }
    function _accountToClaimable(address account) internal view returns (
            uint256 mintedFree,
            uint256 claimableDailyDrops,
            uint256 claimableSacrifices,
            uint256 claimableReferrals,
            uint256 claimableGiveaway
        )
    {
        unchecked {
            mintedFree = _accountToMintedFree(account);
            if (!_isContractPastConstruction(account) && mintedFree < _maxFreePerAccount) {
               

                uint256 mintedFreeFuture = mintedFree;
                uint256 tokensMinted = _tokensMinted();
                if (tokensMinted >= _referralProgramEnds) 
                    return (
                        mintedFree, 
                        claimableDailyDrops, 
                        claimableSacrifices, 
                        claimableReferrals, 
                        claimableGiveaway
                    );
               
               
                if ((_account[account].referralPurchases / _referralsPerReward) > _account[account].mintedReferrals) {
                    claimableReferrals = (_account[account].referralPurchases / _referralsPerReward) - _account[account].mintedReferrals;
                    mintedFreeFuture += claimableReferrals;
                    if (mintedFreeFuture >= _maxFreePerAccount) {
                        return (
                            mintedFree, 
                            claimableDailyDrops, 
                            claimableSacrifices, 
                            claimableReferrals - (mintedFreeFuture - _maxFreePerAccount),
                            claimableGiveaway
                        );
                    }
                }
                if (tokensMinted >= _sacrificeAndDailyDropsOffersEnds)
                    return (
                        mintedFree, 
                        claimableDailyDrops, 
                        claimableSacrifices, 
                        claimableReferrals, 
                        claimableGiveaway
                    ); 
               
               
                if (
                    _account[account].timestampDailyDropLastClaimed != 0 &&
                    _account[account].timestampDailyDropLastClaimed / _dailyDropDuration != block.timestamp / _dailyDropDuration
                ) {
                    claimableDailyDrops = 1;
                    mintedFreeFuture += claimableDailyDrops;
                    if (mintedFreeFuture >= _maxFreePerAccount) {
                        return (
                            mintedFree, 
                            claimableDailyDrops,
                            claimableSacrifices, 
                            claimableReferrals, 
                            claimableGiveaway
                        );
                    }
                }
               
               
                if ((_account[account].tokensBurned / _burnsPerReward) > _account[account].mintedSacrifices) {
                    claimableSacrifices = (_account[account].tokensBurned / _burnsPerReward) - _account[account].mintedSacrifices;
                    mintedFreeFuture += claimableSacrifices;
                    if (mintedFreeFuture >= _maxFreePerAccount) {
                        return (
                            mintedFree, 
                            claimableDailyDrops, 
                            claimableSacrifices - (mintedFreeFuture - _maxFreePerAccount),
                            claimableReferrals, 
                            claimableGiveaway
                        );
                    }
                }
                if (tokensMinted >= _giveawayEnds)
                    return (
                        mintedFree, 
                        claimableDailyDrops, 
                        claimableSacrifices, 
                        claimableReferrals, 
                        claimableGiveaway
                    ); 
               
               
                if (_account[account].mintedGiveaway == 0) {
                    claimableGiveaway = 1;
                    mintedFreeFuture += claimableGiveaway;
                    if (mintedFreeFuture >= _maxFreePerAccount) {
                        return (
                            mintedFree, 
                            claimableDailyDrops, 
                            claimableSacrifices, 
                            claimableReferrals, 
                            claimableGiveaway
                        );
                    }
                }
            }
            return (mintedFree, claimableDailyDrops, claimableSacrifices, claimableReferrals, claimableGiveaway);
        }
    }
    function _accountToMintedFree(address account) internal view returns (uint256 mintedFree) {
        unchecked {
            mintedFree = (
                _account[account].mintedBogos + 
                _account[account].mintedDailyDrops + 
                _account[account].mintedSacrifices + 
                _account[account].mintedReferrals + 
                _account[account].mintedGiveaway
                );
            return mintedFree;
        }
    }
    function _isTradeApproved(
        address maker,
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (bool approved) {
        unchecked {
            if (maker == address(0)) return false;
            if (signature.length != 65) return false;

            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return false;
            if (v != 27 && v != 28) return false;
           
            address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s);
            if (signer == address(0)) return false;

            return (maker == signer);
        }
    }
    function _mint(
        address to,
        uint256 purchase,
        uint256 free,
        uint32 safeBlockTimestamp,
        uint256 tokensMinted
    ) internal {
        unchecked {
            uint256 amount = purchase + free;
            if (to == address(0)) revert THE_ZERO_ADDRESS_CANNOT_HAVE_AN_ACCOUNT();
            if (tokensMinted + amount > _maxSupply) revert AMOUNT_MINTING_SURPASSES_THE_MAX_SUPPLY();
            if (amount == 0) revert CANNOT_MINT_ZERO();
            if (purchase > 0) _tokensMintedPurchase += uint32(purchase);
            if (free > 0) _tokensMintedFree += uint32(free);
            _account[to].tokensOwned += uint16(amount);
            uint256 tokenId = _getTokenId(tokensMinted);
            _token[tokenId].account = to;
            _token[tokenId].mintTimestamp = safeBlockTimestamp;
            purchase = tokensMinted + amount;
            while (tokensMinted != purchase) {
                emit Transfer(     
                    address(0),    
                    to,            
                    ((tokensMinted / _sections) % 2 == 0)  
                    ? ((_distance * (tokensMinted % _sections)) + ((_distance * tokensMinted) / _maxSupply) + 1)
                    : (_maxSupply - ((_distance * (tokensMinted % _sections)) + ((_distance * tokensMinted) / _maxSupply)))
                );
                tokensMinted++;
            }
        }
    }
    function _marketPrice(uint256 tokensMintedPurchase, uint256 tokensMintedFree)
        internal
        view
        returns (
            uint256 price,
            uint256 base,
            uint256 multiplier,
            uint256 decline,
            uint256 bogo
        )
    {
        unchecked {
           
           
            base = ((tokensMintedPurchase * 2) + tokensMintedFree + _tokensBurned) * _basePriceIncrementPerPoint;
            if (tokensMintedPurchase + tokensMintedFree > _increasedVolatilityThreshold) {
                base += ((tokensMintedPurchase + tokensMintedFree) - _increasedVolatilityThreshold) * _basePriceIncrementPerPoint * _volatilityMultiplier;
            }
           
           
            uint256 elapsed = block.timestamp - _purchaseTimestamp;
            if (_declineDuration > elapsed) {
                multiplier = ((_declineDuration - elapsed) * _temporaryDemandMultiplier) / _declineDuration;
            }
            decline = (elapsed * 100000) / _declineDuration;
            if (decline > 100000) decline = 100000;
            price = ((((base * (multiplier + 100000)) / 100000) * (100000 - decline)) / 100000);
            bogo = _bogoStartingFrom;
            if (elapsed >= _bogoDuration) {
                bogo = 1;
                if (_bogoStartingFrom > (elapsed / _bogoDuration)) {
                    bogo = _bogoStartingFrom - (elapsed / _bogoDuration);
                }
            }

            return (price, base, multiplier, decline, bogo);
        }
    }
    function _transfer(address from, address to, uint256 tokenId) internal {
        unchecked {
            if (to == address(0)) revert THE_ZERO_ADDRESS_CANNOT_HAVE_AN_ACCOUNT();
           
            _account[from].tokensOwned--;
            _account[to].tokensOwned++;
            delete _token[tokenId].approval;
           
            _token[tokenId].account = to;

            emit Transfer( 
                from,      
                to,        
                tokenId    
            );
            tokenId = _getTokenIndex(tokenId) + 1;
            if (tokenId < _tokensMinted()) {
                tokenId = _getTokenId(tokenId);
                if (_token[tokenId].account == address(0)) _token[tokenId].account = from;
            }
        }
    }
    function _hasAccess(address account, uint256 tokenId) internal view returns (bool hasAccess, address owner) {
        owner = ownerOf(tokenId);
        return (
                (
                    account == owner ||                    
                    isApprovedForAll(owner, account) ||    
                    getApproved(tokenId) == account        
                ), 
                owner
            );
    }
    function _revertIfNoAccess(address account, uint256 tokenId) internal view returns (address owner) {
        (bool hasAccess, address _owner) = _hasAccess(account, tokenId);
        if (!hasAccess) revert RESTRICTED_ACCESS();
        return _owner;
    }
    function _tokensMinted() internal view returns (uint256 minted) {
        unchecked {
            return _tokensMintedPurchase + _tokensMintedFree;
        }
    }
    function _isTokenSacrificed(uint256 tokenId) internal view returns (bool burned) {
        unchecked {
            return (_token[tokenId].burnTimestamp != 0);
        }
    }
    function _revertIfTokenIsInvalid(uint256 tokenId) internal view {
        unchecked {
            if (_getTokenIndex(tokenId) >= _tokensMinted()) revert INVALID_CRYPTOBLOB_ID();
            if (_isTokenSacrificed(tokenId)) revert CRYPTOBLOB_HAS_BEEN_SACRIFICED();
        }
    }
    function _safeBlockTimestamp() internal view returns (uint32 _seconds) {
        unchecked {
            if (block.timestamp < type(uint32).max) {
                return uint32(block.timestamp);
            } else {
                return type(uint32).max;
            }
        }
    }
    function _isContractPastConstruction(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function _toPaddedString(uint256 value) internal pure returns (string memory) {
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory padding;
        for (uint256 i; i < 5 - digits; i++) {
            padding = abi.encodePacked(padding, "0");
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            buffer[--digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(abi.encodePacked(string(padding), string(buffer)));
    }
    function _interaction(address account, uint256 amount, bytes memory data) internal {
        if (amount > address(this).balance) revert INSUFFICIENT_CONTRACT_BALANCE();
        (bool success, bytes memory returndata) = payable(account).call{value: amount}(data);
        if (!success) {
            if (returndata.length == 0) {
                if (amount > 0) {
                    revert UNABLE_TO_TRANSFER_ETHER();
                } else {
                    revert UNABLE_TO_INTERACT_WITH_CONTRACT();
                }
            } else {
                assembly {
                    revert(add(32, returndata), mload(returndata))
                }
            }
        }
    }
    function _transferEther(address account, uint256 amount) internal {
        _interaction(account, amount, "");
    }
    function _getTokenId(uint256 index) internal pure returns (uint256 tokenId) {
        unchecked {
            if (index >= _maxSupply) revert INVALID_CRYPTOBLOB_ID();
            if ((index / _sections) % 2 == 0) {
                return (_distance * (index % _sections)) + ((_distance * index) / _maxSupply) + 1;
            } else {
                return _maxSupply - ((_distance * (index % _sections)) + ((_distance * index) / _maxSupply));
            }
        }
    }
    function _getTokenIndex(uint256 tokenId) internal pure returns (uint256 index) {
        unchecked {
            if (tokenId > _maxSupply || tokenId < 1) revert INVALID_CRYPTOBLOB_ID();
            uint256 base = tokenId % _distance;
            if (base == 0) base = _distance;
            if (base % 2 != 0) { tokenId--; } else { tokenId = _maxSupply - tokenId; }
            return (((tokenId % _distance) * _sections) + (tokenId / _distance));
        }
    }
}
contract CryptoBlobs is SuperERC721 {
    function mint(uint256 key, address account, uint256 number) external payable nonReentrant {
        unchecked {
            uint256 tokensMintedPurchase = _tokensMintedPurchase;
            uint256 tokensMintedFree = _tokensMintedFree;
            uint32 safeBlockTimestamp = _safeBlockTimestamp();

            if (key == 0) {
               
                (
                    uint256 tokenPrice,,
                    uint256 multiplier,,
                    uint256 bogo
                ) = _marketPrice(tokensMintedPurchase, tokensMintedFree);
                uint256 salePrice = tokenPrice * number;
               
                if (msg.value < salePrice) {

                    if (msg.value >= tokenPrice) {
                        number = msg.value / tokenPrice;
                        salePrice = tokenPrice * number;
                    }
                    if (msg.value < salePrice) revert INSUFFICIENT_FUNDS_SENT_PRICE_MAY_HAVE_INCREASED(salePrice, msg.value);
                }
                if (number > _purchaseLimit) revert PURCHASE_LIMIT_IS_50_PER_TRANSACTION();
               
                _transferEther(msg.sender, (msg.value - salePrice));
                _account[msg.sender].mintedPurchase += uint16(number);
                if (
                    _account[msg.sender].mintedPurchase >= _dailyDropThreshold &&
                    _account[msg.sender].timestampDailyDropLastClaimed == 0
                ) {
                    _account[msg.sender].timestampDailyDropLastClaimed = safeBlockTimestamp;
                }
                uint256 bogoReward;
                if (number >= bogo) {
                    if (msg.sender == tx.origin) {
                        uint256 mintedFree = _accountToMintedFree(msg.sender);
                        if (mintedFree < _maxFreePerAccount) {
                            bogoReward = number / bogo;
                            if (mintedFree + bogoReward > _maxFreePerAccount) {
                                bogoReward = _maxFreePerAccount - mintedFree;
                            }
                            _account[msg.sender].mintedBogos += uint8(bogoReward);
                        }
                    }
                   
                    if (tokensMintedPurchase + tokensMintedFree < _increasedVolatilityThreshold) {
                        _temporaryDemandMultiplier = uint32(multiplier + ((number - (bogoReward / 2)) * _volatilityBase));
                    } else {
                        _temporaryDemandMultiplier = uint32(multiplier + ((number - (bogoReward / 2)) * _volatilityBase * _volatilityMultiplier));
                    }
                } else {
                   
                    if (tokensMintedPurchase + tokensMintedFree < _increasedVolatilityThreshold) {
                        _temporaryDemandMultiplier = uint32(multiplier + (number * _volatilityBase));
                    } else {
                        _temporaryDemandMultiplier = uint32(multiplier + (number * _volatilityBase * _volatilityMultiplier));
                    }
                }
                if (account != address(0)) {
                    if (
                        _account[msg.sender].timestampReferralLinkUsed == 0 &&
                        account != msg.sender &&
                        msg.sender == tx.origin
                    ) {
                        _account[msg.sender].timestampReferralLinkUsed = safeBlockTimestamp;
                        _account[account].referralPurchases += uint16(number);
                    } else {
                        account = address(0);
                    }
                }
                _purchaseTimestamp = safeBlockTimestamp;
                _mint(
                    msg.sender,                                
                    number,                                    
                    bogoReward,                                
                    safeBlockTimestamp,                        
                    tokensMintedPurchase + tokensMintedFree    
                );

                emit MintPurchase( 
                    msg.sender,    
                    account,       
                    ((             
                        ((
                            ((
                                tokenPrice         
                            * 10**2) + number)     
                        * 10**2) + bogoReward)     
                    * 10**10) + block.timestamp)   
                );

            } else {
               
                if (tx.origin != msg.sender || address(uint160(type(uint160).max - key)) != msg.sender) revert RESTRICTED_ACCESS();
                (
                    ,
                    uint256 claimableDailyDrops, 
                    uint256 claimableSacrifices, 
                    uint256 claimableReferrals, 
                    uint256 claimableGiveaway
                ) = _accountToClaimable(msg.sender);
                if (claimableDailyDrops > 0) {
                    _account[msg.sender].mintedDailyDrops += uint8(claimableDailyDrops);
                    _account[msg.sender].timestampDailyDropLastClaimed = safeBlockTimestamp;
                }
                if (claimableSacrifices > 0) {
                    _account[msg.sender].mintedSacrifices += uint8(claimableSacrifices);
                }
                if (claimableReferrals > 0) {
                    _account[msg.sender].mintedReferrals += uint8(claimableReferrals);
                }
                if (claimableGiveaway > 0) {
                    if (account != address(0) && _redeemNFT(account, number)) {
                        _account[msg.sender].mintedGiveaway += uint8(claimableGiveaway);
                    } else {
                        delete claimableGiveaway;
                        delete account;
                        delete number;
                    }
                } else {
                    delete account;
                    delete number;
                }
                uint256 claimableTotal = claimableDailyDrops + claimableSacrifices + claimableReferrals + claimableGiveaway;
                if (claimableTotal == 0) revert ACCOUNT_HAS_NOTHING_TO_CLAIM();
               
                if (claimableTotal >= 2) {
                    uint256 multiplierIncrement;
                    if (tokensMintedPurchase + tokensMintedFree < _increasedVolatilityThreshold) {
                        multiplierIncrement = (claimableTotal / 2) * _volatilityBase;
                    } else {
                        multiplierIncrement = (claimableTotal / 2) * _volatilityBase * _volatilityMultiplier;
                    }
                    if (_temporaryDemandMultiplier > multiplierIncrement) {
                        _temporaryDemandMultiplier -= uint32(multiplierIncrement);
                    } else {
                        delete _temporaryDemandMultiplier;
                    }
                }
                _mint(
                    msg.sender,                                
                    0,                                         
                    claimableTotal,                            
                    safeBlockTimestamp,                        
                    tokensMintedPurchase + tokensMintedFree    
                );

                emit MintFree(     
                    msg.sender,    
                    account,       
                    number,        
                    ((             
                        ((
                            ((
                                claimableDailyDrops            
                            * 10**2) + claimableSacrifices)    
                        * 10**2) + claimableReferrals)         
                    * 10**10) + block.timestamp)               
                );
            }
        }
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert CANNOT_APPROVE_THIS_ADDRESS();
       
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert RESTRICTED_ACCESS();
        _token[tokenId].approval = to;

        emit Approval( 
            owner,     
            to,        
            tokenId    
        );
    }
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        unchecked {
            if (msg.sender == operator) revert CANNOT_APPROVE_THIS_ADDRESS();
           
           

            if (approved) {
                _account[msg.sender].approvals[operator] = 2;
            } else {
                _account[msg.sender].approvals[operator] = 1;
            }

            emit ApprovalForAll(   
                msg.sender,        
                operator,          
                approved           
            );
        }
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
       
        address owner = _revertIfNoAccess(msg.sender, tokenId);
        if (owner != from) revert FROM_ADDRESS_DOES_NOT_MATCH_THE_OWNERS_ADDRESS();
        _transfer(owner, to, tokenId);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (_isContractPastConstruction(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) revert CONTRACT_DOES_NOT_HAVE_ONERC721RECEIVED_IMPLEMENTED();
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert CONTRACT_DOES_NOT_HAVE_ONERC721RECEIVED_IMPLEMENTED();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
    function batch(
        bytes[] memory batchDataEncoded
    ) external {
        unchecked {
            for (uint256 i; i < batchDataEncoded.length; i++) {
                BatchData memory batchData = abi.decode(batchDataEncoded[i], (BatchData));
                if (batchData.category == 0) {
                    transferFrom(batchData.account1, batchData.account2, batchData.tokenId);
                } else if (batchData.category == 1) {
                    setApprovalForAll(batchData.account1, batchData.approved);
                } else if (batchData.category == 2) {
                    approve(batchData.account1, batchData.tokenId);
                } else if (batchData.category == 3) {
                    manageTrades(batchData.account1, batchData.hash);
                } else if (batchData.category == 4) {
                    optimize(batchData.tokenIds);
                } else if (batchData.category == 5) {
                    sacrifice(batchData.tokenId, batchData.tokenIds);
                }
            }
        }
    }
    function manageTrades(
        address account,
        bytes32 hash
    ) public {
        unchecked {
            if (msg.sender != account && !isApprovedForAll(account, msg.sender)) revert RESTRICTED_ACCESS();

            if (hash == 0x0000000000000000000000000000000000000000000000000000000000000000) {
                delete _account[account].timestampTradesLocked;
            } else if (hash == 0x0000000000000000000000000000000000000000000000000000000000000001) {
                _account[account].timestampTradesLocked = _safeBlockTimestamp();
            } else if (_account[account].timestampTradeHashUsed[hash] == 0) {
                _account[account].timestampTradeHashUsed[hash] = block.timestamp * 10;
            } else {
                revert RESTRICTED_ACCESS();
            }

            uint256[] memory empty = new uint256[](0);
            emit Trade(            
                hash,              
                account,           
                msg.sender,        
                empty,             
                empty,             
                0,                 
                0,                 
                block.timestamp,   
                false              
            );
        }
    }
    function trade(
        address maker,
        address taker,
        uint256[] memory makerIds,
        uint256[] memory takerIds,
        uint256 price,
        uint256 expiry,
        uint256 salt,
        bytes memory signature
    ) external payable nonReentrant {
        unchecked {
            if (_tradingPaused) revert TRADING_IS_CURRENTLY_DISABLED();
            if (taker != address(0) && msg.sender != taker) revert TRADE_IS_NOT_FOR_YOU();
            if (msg.value < price) revert INSUFFICIENT_FUNDS_SENT();
            (bytes32 hash, uint256[8] memory errors) = isTradeApprovedAndValid(
                maker,
                taker,
                makerIds,
                takerIds,
                price,
                expiry,
                salt,
                signature, 
                false
            );
            for (uint256 i; i < errors.length; i++) if (errors[i] != 0) revert INVALID_TRADE();
            if (price > 0) _transferEther(maker, price);
           
           
            for (uint256 i; i < makerIds.length; i++) _transfer(_revertIfNoAccess(maker, makerIds[i]), msg.sender, makerIds[i]);
            for (uint256 i; i < takerIds.length; i++) _transfer(_revertIfNoAccess(msg.sender, takerIds[i]), maker, takerIds[i]);
           
            _account[maker].timestampTradeHashUsed[hash] = (block.timestamp * 10) + 1;

            emit Trade(            
                hash,              
                maker,             
                msg.sender,        
                makerIds,          
                takerIds,          
                price,             
                expiry,            
                block.timestamp,   
                true               
            );
        }
    }
    function optimize(
        uint256[] memory tokenIds
    ) public {
        unchecked {
            uint256 amount = tokenIds.length;
            for (uint256 i; i < amount; i++) {
                if (_token[tokenIds[i]].account != address(0)) revert CRYPTOBLOB_DOES_NOT_REQUIRE_OPTIMIZATION();
                _token[tokenIds[i]].account = ownerOf(tokenIds[i]);
            }
            _account[msg.sender].tokensOptimized += uint16(amount);

            emit Optimize(             
                msg.sender,            
                tokenIds,              
                block.timestamp        
            );
        }
    }
    function sacrifice(
        uint256 tokenIdUpgrading,
        uint256[] memory tokenIdsSacrificing
    ) public {
        unchecked {
            if (_sacrificingPaused) revert SACRIFICING_IS_CURRENTLY_DISABLED();
            _revertIfTokenIsInvalid(tokenIdUpgrading);

            uint16 totalSouls;
            uint256 amount = tokenIdsSacrificing.length;
            uint32 safeBlockTimestamp = _safeBlockTimestamp();

            for (uint256 i; i < amount; i++) {
                uint256 tokenIdSacrificing = tokenIdsSacrificing[i];
                if (tokenIdSacrificing == tokenIdUpgrading) revert INVALID_CRYPTOBLOB_ID();
                address owner = _revertIfNoAccess(msg.sender, tokenIdSacrificing);
                _account[owner].tokensOwned--;
                _account[owner].tokensBurned++;
                delete _token[tokenIdSacrificing].approval;
               
                _token[tokenIdSacrificing].burnTo = uint16(tokenIdUpgrading);
                _token[tokenIdSacrificing].souls++;
                totalSouls += _token[tokenIdSacrificing].souls; 
                if (_token[tokenIdSacrificing].account != owner) _token[tokenIdSacrificing].account = owner;
                _token[tokenIdSacrificing].burnTimestamp = safeBlockTimestamp;
                emit Transfer(             
                    owner,                 
                    address(0),            
                    tokenIdSacrificing     
                );

            }
            _token[tokenIdUpgrading].souls += totalSouls;
            _tokensBurned += uint32(amount);
        }
    }
    function manageContract(
        uint256 category,
        address[] memory _address,
        uint256[] memory _uint,
        string[] memory _string,
        bytes memory _bytes
    ) external payable nonReentrant {
        unchecked {
            if (msg.sender == _contractOwner) {
                if (category == 0) {
                    _name = _string[0];
                } else if (category == 1) {
                    _contractURI = _string[0];
                } else if (category == 2) {
                    _tokenURIPrefix = _string[0];
                } else if (category == 3) {
                    uint256 startFrom = _uint[0];
                    for (uint256 i; i < _string.length; i++) {
                        _tokenURIPrefixes[i + startFrom] = _string[i];
                    }
                } else if (category == 4) {
                    _URIMaxSoulsLimit = _uint[0];
                } else if (category == 5) {
                    _tradingPaused = !_tradingPaused;
                } else if (category == 6) {
                    _sacrificingPaused = !_sacrificingPaused; 
                } else if (category == 7) {
                   
                   
                    for (uint256 i; i < _address.length; i++) {
                        if (
                            _account[_address[i]].preapprovedStatus == 1 ||
                            _account[_address[i]].preapprovedStatus == 2
                        ) { 
                           
                            _account[_address[i]].preapprovedStatus = _uint[i];
                        } else {
                            revert();
                        }
                    }
                } else if (category == 8) {
                    _reverseRecordsAddress = _address[0];
                } else if (category == 9) {
                    _contractCandidate = _address[0];
                } else if (category == 10) {
                    uint32 safeBlockTimestamp = _safeBlockTimestamp();
                    for (uint256 i; i < _address.length; i++) {
                        uint8 amount = uint8(_uint[i]);
                        if (amount > _purchaseLimit) revert();
                        address recipient = _address[i];
                        _account[recipient].mintedSpecial += amount;
                        _mint(
                            recipient,             
                            0,                     
                            amount,                
                            safeBlockTimestamp,    
                            _tokensMinted()        
                        );
                    }
                } else if (category == 11) {
                    _interaction(_address[0], _uint[0], _bytes);
                } else {
                    _transferEther(_contractOwner, address(this).balance);
                }
            } else if (_contractCandidate != address(0) && msg.sender == _contractCandidate) {
                emit OwnershipTransferred(     
                    _contractOwner,            
                    _contractCandidate         
                );
                _contractOwner = _contractCandidate;
                delete _contractCandidate;
            } else {
                revert RESTRICTED_ACCESS();
            }
        }
    }
    function metadata(
        string memory table,
        string memory key,
        string memory value
    ) external {
        emit Metadata(         
            msg.sender,        
            table,             
            key,               
            value,             
            block.timestamp    
        );
    }

}
error RESTRICTED_ACCESS();
error REENTRANT_CALLS_ARE_NOT_ALLOWED();
error INSUFFICIENT_CONTRACT_BALANCE();
error UNABLE_TO_TRANSFER_ETHER();
error UNABLE_TO_INTERACT_WITH_CONTRACT();
error THE_ZERO_ADDRESS_CANNOT_HAVE_AN_ACCOUNT();
error INVALID_CRYPTOBLOB_ID();
error CRYPTOBLOB_HAS_BEEN_SACRIFICED();
error CANNOT_APPROVE_THIS_ADDRESS();
error CONTRACT_DOES_NOT_HAVE_ONERC721RECEIVED_IMPLEMENTED();
error FROM_ADDRESS_DOES_NOT_MATCH_THE_OWNERS_ADDRESS();
error OWNERS_BALANCE_IS_INSUFFICENT_FOR_THE_INDEX();
error CANNOT_MINT_ZERO();
error AMOUNT_MINTING_SURPASSES_THE_MAX_SUPPLY();
error PURCHASE_LIMIT_IS_50_PER_TRANSACTION();
error INSUFFICIENT_FUNDS_SENT_PRICE_MAY_HAVE_INCREASED(
    uint256 price,
    uint256 received
);
error INSUFFICIENT_FUNDS_SENT();
error INVALID_TRADE();
error NFT_IS_NOT_ELIGIBLE();
error ACCOUNT_HAS_NOTHING_TO_CLAIM();
error TRADING_IS_CURRENTLY_DISABLED();
error SACRIFICING_IS_CURRENTLY_DISABLED();
error CRYPTOBLOB_DOES_NOT_REQUIRE_OPTIMIZATION();
error TRADE_IS_NOT_FOR_YOU();