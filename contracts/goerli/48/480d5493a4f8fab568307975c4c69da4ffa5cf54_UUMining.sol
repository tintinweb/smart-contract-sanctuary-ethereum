/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IERC721 {
    function exist(uint tokenId) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address _owner) external view returns (uint256);
    function mint(address to, uint256 amt) external;
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function decimals() external view returns (uint8 decimals);
    function transferFrom(address _from, address _to, uint256 _value) external;    
    function transfer(address to, uint256 _value) external;
    function approve(address _spender, uint256 _value) external returns (bool success);
}

contract UUMining is Ownable {

    address public minerNftAddr;
    address public lootNftAddr;
    address public uuTokenAddr;
    address public usdtAddr;
    address public uuTokenWallet; // holding uuToken

    uint public CONST_UURATE = 1; // num of days to finish distributing. 0.1% per day

    uint256 public mintedMinerIndex = 0; 
    uint256 public mintedLootIndex = 0; 

    uint256 public treasureMapOdds = 5;
    uint256 public lootBoxOdds = 5;
    uint256 public treasureMapPrize = 5;
    uint256 public lootBoxPrize = 1;

    mapping (address => address) public userToReferrer;
    mapping (address => uint8) public numberOfFirstRefer;
    mapping (address => uint8) public numberOfSecondRefer;
    mapping (address => uint256) public userInvestedAmt; // usdt
    mapping (address => uint256) public referralUUReward;  // uu
    mapping (address => bool) public blacklistedUsers; 
    mapping (address => UserDetail) public allUserDetails;
    
    MinerNFTdetail[] public allMinerNftDetails;
    LootNFTdetail[] public allLootNftDetails;

    struct UserDetail {
        uint256 claimedLoot; 
        uint256 lastClaimTime;
        uint256 rewardedAmt; // the sum of prize received
    }

    struct MinerNFTdetail { 
        uint256 totalUU;
        uint256 claimedUU;
        uint256 UUrate; // i.e. num of days to finish distributing. 0.2% per day
        uint256 createdTime;
        bool valid; // invalid when burn
        uint256 id; 
    }

    struct LootNFTdetail { 
        uint256 lootType; // either treasureMap or LootBox. 1: Map, 2: Box
        uint256 prize;
        uint256 odds; 
        uint256 createdTime;
        bool isOpened; 
        uint256 id;
    }

    event MintedMinerNFT(address target, uint256 amt, uint256 nftId);
    event MintedLootNFT(address target, uint256 amt, uint256 nftId);
    event SplitMinerNFT(uint256 nftId, uint256 uuAmt);
    event ClaimUU(uint256 nftId, uint256 claimAmt, uint256 totalClaimed);
    event OpenLootBox(address user, uint256 nftId, uint256 result);

    modifier onlyValidUsers() {
        require(isUserBlacklisted(_msgSender()) != true, "caller is blacklisted.");
        _;
    }
    
    constructor(address _minerNftAddr, address _lootNftAddr, address _uuTokenAddr, address _usdtAddr, address _uuTokenWallet) {
        minerNftAddr = _minerNftAddr; 
        lootNftAddr = _lootNftAddr; 
        uuTokenAddr = _uuTokenAddr;
        usdtAddr = _usdtAddr; 
        uuTokenWallet = _uuTokenWallet;
    }

    function mint100(uint256 _amt, address _referrer) public {
        _mint(_amt, _referrer, 100); 
    }

    function mint10000(uint256 _amt, address _referrer) public {
        _mint(_amt, _referrer, 10000); 
    }
    
    function _mint(uint256 _amt, address _referrer, uint256 _usdtPrice) internal onlyValidUsers {
        require (_amt > 0, "mint amount must larger than 0");

        // check if caller has sufficient usdt
        IERC20 usdt = IERC20(usdtAddr);
        uint256 requiredUsdt = _usdtPrice * _amt;
        require(usdt.balanceOf(msg.sender) >= requiredUsdt, 'insufficient USDT to mint');

        // get referrers
        address firstReferrer;
        address secondReferrer;
        if (userToReferrer[msg.sender] == address(0) && _referrer != address(0)) { // update referrer only if record empty + hv input
            userToReferrer[msg.sender] = _referrer;  
            numberOfFirstRefer[_referrer] += 1;
        }
        firstReferrer = userToReferrer[msg.sender];
        secondReferrer = userToReferrer[firstReferrer];
        numberOfSecondRefer[secondReferrer] += 1;

        _callMintingMinerNft(msg.sender, _amt, (_usdtPrice*2), 0); // mint to caller
        userInvestedAmt[msg.sender] += requiredUsdt;

        if (msg.sender != firstReferrer && userInvestedAmt[firstReferrer] >= _usdtPrice) {
            _callMintingMinerNft(firstReferrer, _amt, (_usdtPrice), 0); // mint to 1st referrer
            referralUUReward[firstReferrer] += _amt * _usdtPrice;
        }
        if (msg.sender != secondReferrer && userInvestedAmt[secondReferrer] >= _usdtPrice) {
            _callMintingMinerNft(secondReferrer, _amt, (_usdtPrice/2), 0); // mint to 2nd referrer
            referralUUReward[secondReferrer] += _amt * (_usdtPrice/2);
        }
        
        usdt.transferFrom(msg.sender, address(this), requiredUsdt*1000000); // collect usdt with 6 decimals
    }

    function _callMintingMinerNft(address _target, uint256 _amt, uint256 _totalUU, uint256 _claimedUU) internal {
        if (_target != address(0)) {
            // need mintedMinerIndex but can only do one contract
            IERC721 minerNft = IERC721(minerNftAddr);
            minerNft.mint(_target, _amt); 
            emit MintedMinerNFT(_target, _amt, mintedMinerIndex);
            
            for (uint256 i = 0; i < _amt; i++) {
                // update miner nft detail 
                MinerNFTdetail memory newNft = MinerNFTdetail({
                    totalUU: _totalUU,
                    claimedUU: _claimedUU,
                    UUrate: CONST_UURATE, 
                    createdTime: block.timestamp,
                    valid: true,
                    id: mintedMinerIndex
                });
                allMinerNftDetails.push(newNft);
                mintedMinerIndex += 1;
            }
        }
    }


    function _callMintingLootNft(address _target, uint256 _amt, uint256 _type, uint256 _prize, uint256 _odds) internal {
        if (_target != address(0)) {
            // mintedLootIndex 
            IERC721 lootNft = IERC721(lootNftAddr);
            lootNft.mint(_target, _amt); 
            emit MintedLootNFT(_target, _amt, mintedLootIndex);
            
            for (uint256 i = 0; i < _amt; i++) {
                // update loot nft detail 
                LootNFTdetail memory newNft = LootNFTdetail({
                    lootType: _type,
                    prize: _prize,
                    odds: _odds,
                    createdTime: block.timestamp,
                    isOpened: false,
                    id: mintedLootIndex
                });
                allLootNftDetails.push(newNft);

                mintedLootIndex += 1;
            }
        }
    }
    
    function claimUU(uint _id) public onlyValidUsers {
        // check if caller owns NFT
        IERC721 _thisNFT = IERC721(minerNftAddr);
        require (msg.sender == _thisNFT.ownerOf(_id), "not NFT owner.");

        // check if valid
        MinerNFTdetail storage n = allMinerNftDetails[_id];
        require (n.valid, 'NFT not valid.');

        // calculate UU available to claim
        uint256 claimableUU =  ((block.timestamp - n.createdTime) * n.totalUU / n.UUrate / 86400); 
        uint256 available2ClaimUU = claimableUU - n.claimedUU;
        require (available2ClaimUU > 0, 'no UU available to claim');

        // check if this contract has enough UU 
        IERC20 UUtoken = IERC20(uuTokenAddr);
        uint8 decimals = UUtoken.decimals();
        require (UUtoken.balanceOf(address(uuTokenWallet)) >= available2ClaimUU * 10 ** decimals, 'Insuffient UU for claiming');

        // do claiming and update
        _transferUUToken(msg.sender, available2ClaimUU * 10 ** decimals);
        n.claimedUU += available2ClaimUU;

        emit ClaimUU(_id, available2ClaimUU, n.claimedUU);
    }
    
    function _internalClaimUU(uint _id, address claimer) internal {
        // check if caller owns NFT
        IERC721 _thisNFT = IERC721(minerNftAddr);
        require (claimer == _thisNFT.ownerOf(_id), "not NFT owner.");

        // check if valid
        MinerNFTdetail storage n = allMinerNftDetails[_id];
        require (n.valid, 'NFT not valid.');

        // calculate UU available to claim
        uint256 claimableUU =  ((block.timestamp - n.createdTime) * n.totalUU / n.UUrate / 86400); 
        uint256 available2ClaimUU = claimableUU - n.claimedUU;
        require (available2ClaimUU > 0, 'no UU available to claim');

        // check if this contract has enough UU 
        IERC20 UUtoken = IERC20(uuTokenAddr);
        uint8 decimals = UUtoken.decimals();

        // do claiming and update
        _transferUUToken(claimer, available2ClaimUU * 10 ** decimals);
        n.claimedUU += available2ClaimUU;

        emit ClaimUU(_id, available2ClaimUU, n.claimedUU);
    }


    function multiClaimUU(uint[] memory _ids) public onlyValidUsers {
        for (uint i = 0; i < _ids.length; i++) {
            _internalClaimUU(_ids[i], msg.sender);
        }
    }

    function splitNftInto2(uint _id, uint _uuAmt) public onlyValidUsers {
        // check if caller owns NFT
        IERC721 _thisNFT = IERC721(minerNftAddr);
        require (msg.sender == _thisNFT.ownerOf(_id), "not NFT owner.");

        // check input _uuAmt, if in the range of remainingUU (i.e. uuTotal - ClaimedUU)
        MinerNFTdetail storage oldNft = allMinerNftDetails[_id];
        uint256 remainUU = oldNft.totalUU - oldNft.claimedUU;
        require (_uuAmt < remainUU && _uuAmt > 0, "input UU-amount out of range");
        
        uint256 claimableUU =  ((block.timestamp - oldNft.createdTime) * oldNft.totalUU / oldNft.UUrate / 86400); 
        uint256 available2ClaimUU = claimableUU - oldNft.claimedUU;
        // check if this contract has enough UU 
        IERC20 UUtoken = IERC20(uuTokenAddr);
        uint8 decimals = UUtoken.decimals();
        // do claiming before split
        _transferUUToken(msg.sender, available2ClaimUU * 10 ** decimals);

        oldNft.valid = false; 
        
        _callMintingMinerNft(msg.sender, 1, _uuAmt, 0);
        _callMintingMinerNft(msg.sender, 1, remainUU - _uuAmt, 0);

        emit SplitMinerNFT(_id, _uuAmt);        
    }

    function obtainTreasures() public onlyValidUsers {
        UserDetail memory u = allUserDetails[msg.sender];
        if (block.timestamp - u.lastClaimTime >= 43200) { // can claim after 12 hr

            uint256 _type = 2; // lootbox
            uint256 _prize = lootBoxPrize;
            uint256 _odds = lootBoxOdds;
            if (userInvestedAmt[msg.sender] >= 10000) { // switch to treasureMap
                _type = 1; 
                _prize = treasureMapPrize; 
                _odds = treasureMapOdds;
            }
            u.lastClaimTime = block.timestamp;

            _callMintingLootNft(msg.sender, 1, _type, _prize, _odds);
        } 
    }

    function openTreasures(uint256 _id) public onlyValidUsers returns (uint256 value) {
        LootNFTdetail storage loot = allLootNftDetails[_id];
        require (!loot.isOpened, "Loot Box/Map already opened.");
        require (userInvestedAmt[msg.sender] >= 100, "not for free users.");

        bool case1 = loot.lootType == 1 && userInvestedAmt[msg.sender] >= 10000;
        bool case2 = loot.lootType == 2 && userInvestedAmt[msg.sender] >= 100;
        uint256 prize = 0;
        if (case1 || case2) {
            if (_generateRandomNum(loot.odds) == 1) {
                IERC20 UUtoken = IERC20(uuTokenAddr);
                uint8 decimals = UUtoken.decimals();
                _transferUUToken(msg.sender,  loot.prize * 10 ** decimals); // give prize
                prize = loot.prize;
            }

            loot.isOpened = true;
            emit OpenLootBox(msg.sender, _id, prize);       

        }         
        return prize;
    }

    function _generateRandomNum(uint256 odds) internal view returns (uint256 rand) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % (odds) ;
    }    

    function isValidNFT(uint256 _id) public view returns (bool) {
        require (_id < mintedMinerIndex, 'NFT not exist.');
        MinerNFTdetail memory n = allMinerNftDetails[_id];
        return n.valid;
    }

    function getUserDetail (address _addr) public view
    returns (uint256, uint256, uint256)
    {
        require(_addr != address(0), 'not valid address');
        UserDetail memory u = allUserDetails[_addr];
        return (
            u.claimedLoot,
            u.lastClaimTime,
            u.rewardedAmt
        );
    }

    function getMinerNftDetail(uint _id) public view
    returns(uint256, uint256, uint256, uint256, bool, uint256)
    {
        require(_id < mintedMinerIndex, 'NFT not exist.');
        MinerNFTdetail memory n = allMinerNftDetails[_id];
        return (
            n.totalUU,
            n.claimedUU,
            n.UUrate,
            n.createdTime,
            n.valid,
            n.id
        );
    }

    function getLootNftDetail(uint _id) public view
    returns(uint256, uint256, uint256, uint256, bool, uint256)
    {
        require(_id < mintedLootIndex, 'NFT not exist.');
        LootNFTdetail memory n = allLootNftDetails[_id];
        return (
            n.lootType,
            n.prize,
            n.odds,
            n.createdTime,
            n.isOpened,
            n.id
        );
    }

    function get1stReferrer(address user) public view returns (address) {
        return userToReferrer[user];
    }

    function get2ndReferrer(address user) public view returns (address) {
        return userToReferrer[userToReferrer[user]];
    }


    function getNumberOfFirstRefer(address user) public view returns (uint8) {
        return numberOfFirstRefer[user];
    }

    function getNumberOfSecondRefer(address user) public view returns (uint8) {
        return numberOfSecondRefer[user];
    }

    function getReferredAmt(address user) public view returns (uint256) {
        return referralUUReward[user];
    }

    function isUserBlacklisted(address _user) public view returns(bool) {
        return blacklistedUsers[_user] == true;
    }

    function addUserToBlacklist(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            blacklistedUsers[_users[i]] = true;
        }        
    }

    function removeUserFromBlacklist(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            blacklistedUsers[_users[i]] = false;
        }
    }

    function editTreasureMapOdds(uint256 _newOdds) public onlyOwner {
        treasureMapOdds = _newOdds;
    }

    function editLootBoxOdds(uint256 _newOdds) public onlyOwner {
        lootBoxOdds = _newOdds;
    }

    function editTreasureMapPrize(uint256 _newPrize) public onlyOwner {
        treasureMapPrize = _newPrize;
    }

    function editLootBoxPrize(uint256 _newPrize) public onlyOwner {
        lootBoxPrize = _newPrize;
    }

    function updateUUTokenWallet(address _newUUWallet) public onlyOwner {
        uuTokenWallet = _newUUWallet;
    }

    function updateRate(uint _newRate) public onlyOwner {
        CONST_UURATE = _newRate;
    }



    function _transferUUToken (address _target, uint256 _amt) internal {
        IERC20 erc20token = IERC20(uuTokenAddr);
        require (erc20token.balanceOf(address(uuTokenWallet)) >= _amt, 'insufficent uuToken for transfer');
        erc20token.transferFrom(address(uuTokenWallet), _target, _amt); // todo: add back 18 decimals
    }

    function withdrawErc20Token (address _tokenAddr, uint256 _withdrawAmt) public onlyOwner {
        IERC20 erc20token = IERC20(_tokenAddr);
        uint8 decimals = erc20token.decimals();
        require (erc20token.balanceOf(address(this)) >= _withdrawAmt * 10 ** decimals, 'insufficent token for withdrawal');
        erc20token.transfer(address(owner()), _withdrawAmt * 10 ** decimals);
    }

    function kill() external onlyOwner {
        selfdestruct(payable(address(owner())));
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

}