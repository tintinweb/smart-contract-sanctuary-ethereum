// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


/// @title Marketplace Contract
/// @author FiveRivers Technalogies
/// @notice You as a marketplace for AI Studio Modules 
/// @dev All function calls are currently implemented without any security testing, have a look at TODOs

// TODO: Questions in Sheet

interface IFRTNFT {
    function burn( address account, uint256 id, uint256 value) external;
    function uri(uint256 tokenId) external view returns (string memory); 
    function publisherOf(uint256 tokenId) external view returns (address);
    function getTokenURI(uint256 tokenId) external view returns(string memory);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function mint(address recipient, string memory _tokenURI, uint256 amount) external returns (uint256);
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

contract FRTMarketplace004 is AccessControl{

    event ListNFT(uint256);
    event UnlistNFT(uint256);
    event NFTApproved(uint256);
    event NFTRejected(uint256);
    event BuyNFT(uint256, address, uint256);
    event VoteNFT(uint256, address, string);
    event MintNFT(uint256, address, string, uint256);
    event BuyNFTForVoting(uint256, address);
    event UpdateBaseAddresses(string, address);
    event UpdateBaseValue(string, uint256);
    event RateNFT(uint256, string, address, uint8);

    struct Vote{
        address[] up;
        address[] down;
    }

    struct Refund{
       uint256 time; // {time} after which user can withdraw {amount} tokens
       uint256 amount;
    } 
    
    struct Reward{
        uint256 reward;
        uint256 year;
        uint256 modules;
        uint256 publishedModules;
        uint256 issuedReward;
        uint256 maxReward;
    }

    enum Voted {
        None,
        Up,
        Down
    }

    enum NFTStatus {
        None, 
        Pending,
        Listed,
        Unlisted,
        Rejected
    }

    struct NFTDetail{
        uint256 nftId;
        NFTStatus status;
        uint256 balance;
    }
    IERC20 public baseToken;
    IFRTNFT public baseNFT;
    

    uint256 public baseTokenReward;     // Token reward for publishing a Module
    uint256 public baseNFTPrice;        // Price in {baseTokens} for one copy of a Module
    uint256 public baseVoteReward;      // A reward that contributers (Voters) will get if their vote was in majority 
    uint256 public baseTestingPrice;    // A price that contributers will pay for testing & submiting their vote for a Module
    uint256 public baseNFTAmount;       // Total number of copies created when a Module is created
    uint256 public approvalVotes;       // Minimum number of up-votes required to approve a Module
    uint256 public maxVotes;            // Maximum number of vote that can be submitted for a Module
    uint256 public baseWelcomeReward;   // A Token reward for installing out app
    uint256 public forceTestDuration;   // A minimum time duration to force users to test for a certails time before submit their vote
    uint256 public contractCreatedAt;   // A timstamp when this contract was deployed


    mapping(uint256 => Reward) public rewardsData;                          // Information to issue reward based on contract's age
    mapping(uint256 => Vote) internal NFTVotes;                             // Votes submited by community members 
    mapping(string => bool) public mintedURIs;                              // To keep record of URIs/Hashes of minted Modules
    mapping(uint256 => NFTStatus) public NFTList;                           // List of all NFTs 
    mapping(address => uint256) public voterTestingNFTs;                    // A counter for each vote to keeps track of how many Modules he has downloaded (and not voted yet) for testing
    mapping(uint256 => mapping(address => Voted)) public votedAlready;      // Keep tract of User to Module votes
    mapping(address => mapping(uint256 => Refund)) public voteRefunds;      // Refunds issued to the minority voters
    mapping(address => mapping(uint256 => uint256)) public rewardBalance;   // Rewards {baseVoteReward} issued to the majority voters 
    mapping(uint256 => mapping(address => uint256)) public testingAllowed;  // Keeps record of if a  User is allowed to Votes a Module, User have to pay to get voting rights for each Module
    // mapping(address => uint256[]) public NFTOwners;
    mapping(uint256 => mapping(address => uint8)) public NFTRatings;        // Keeps Record of ratings submitted by user

    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");
    
    /**
     *   @dev Sets the contract addresses for {baseToken} and {baseNFT}.
     *   @dev Sets the values for {maxVotes}, {approvalVotes}, {baseNFTPrice}, {baseTokenReward}, {baseNFTAmount}, {baseTestingPrice}, {baseVoteReward}, {contractCreatedAt} and {forceTestDuration}.
     *   @dev The default value of {decimals} is 18.
     *   @dev All two of these values are mutable through setter funtions: they can only be canged by owner of contract
     *   
     *   @param tokenAddress ERC20 token address 
     *   @param nftAddress ERC1155 token address 
     */
    constructor( address tokenAddress, address nftAddress ){
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TOKEN_MANAGER_ROLE, msg.sender);

        baseToken = IERC20(tokenAddress);
        baseNFT = IFRTNFT(nftAddress);

        maxVotes = 3;
        approvalVotes = 2;
        baseNFTPrice = 5*(10**18);
        baseTokenReward = 5*(10**18);
        baseNFTAmount = 10**9; // 1 billion
        baseTestingPrice = 25 * (10**16);
        baseVoteReward = 5*baseTestingPrice;
        baseWelcomeReward = 15*(10**18);
        // forceTestDuration = 1 minutes; 

        contractCreatedAt = block.timestamp; 

    }
    

    /**
     * @dev Throws if called by any account other than the one who have DEFAULT_ADMIN_ROLE.
     */
    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    /******UPDATE BASE VARIABLES START******/

    /**
     * @dev Sets the contract addresses for {baseToken} and {baseNFT}.
     *
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     * - `_tokenAddress` and `_nftAddress` cannot be the zero address.
     * 
     * Emits a {UpdateBaseAddresses} event with value name as `baseToken` and value `_tokenAddress`.
     * Emits a {UpdateBaseAddresses} event with value name as `baseNFT` and value `_nftAddress`.
     *
     * @param _tokenAddress ERC20 token address 
     * @param _nftAddress ERC1155 token address 
     * 
     */
    function updateBaseAddresses(address _tokenAddress, address _nftAddress ) external onlyOwner{
        require(_tokenAddress != address(0) && _nftAddress != address(0), "FRTMarketplace: can not add zero address");

        baseToken = IERC20(_tokenAddress);
        baseNFT = IFRTNFT(_nftAddress);

    }

    /**
     * @dev Sets value for {baseVoteReward}.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     * 
     * Emits a {UpdateBaseValue} event with value name as `baseVoteReward` and value `_baseVoteReward`.
     *
     * @param _baseVoteReward 18 decimal uint256 number   
     * 
     */
    function updateVoteReward(uint256 _baseVoteReward) external onlyOwner{
        baseVoteReward = _baseVoteReward;

        emit UpdateBaseValue("baseVoteReward", _baseVoteReward);
    }

    /**
     * @dev Sets value for {baseWelcomeReward}.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     * 
     * Emits a {UpdateBaseValue} event with value name as `baseWelcomeReward` and value `_baseWelcomeReward`.
     *
     * @param _baseWelcomeReward 18 decimal uint256 number   
     * 
     */
    function updateWelcomeReward(uint256 _baseWelcomeReward) external onlyOwner{
        baseWelcomeReward = _baseWelcomeReward;

        emit UpdateBaseValue("baseWelcomeReward", _baseWelcomeReward);
    }

    /**
     * @dev Sets value for {baseNFTPrice}.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     * 
     * Emits a {UpdateBaseValue} event with value name as `baseNFTPrice` and value `_baseNFTPrice`.
     *
     * @param _baseNFTPrice 18 decimal uint256 number   
     * 
     */
    function updateNFTPrice(uint256 _baseNFTPrice) external onlyOwner{
        baseNFTPrice = _baseNFTPrice;

        emit UpdateBaseValue("baseNFTPrice", _baseNFTPrice);
    }

    /**
     * @dev Sets value for {baseTestingPrice}.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     * 
     * Emits a {UpdateBaseValue} event with value name as `baseTestingPrice` and value `_baseTestingPrice`.
     *
     * @param _baseTestingPrice 18 decimal uint256 number   
     *
     */
    function updateTestingPrice(uint256 _baseTestingPrice) external onlyOwner{
        baseTestingPrice = _baseTestingPrice;
      
        emit UpdateBaseValue("baseTestingPrice", _baseTestingPrice);
    }

    /**
     * @dev Sets value for {baseNFTAmount}.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     * 
     * Emits a {UpdateBaseValue} event with value name as `baseNFTAmount` and value `_baseNFTAmount`.
     *
     * @param _baseNFTAmount 18 decimal uint256 number   
     * 
     */
    function updateNFTAmount(uint256 _baseNFTAmount) external onlyOwner{
        baseNFTAmount = _baseNFTAmount;
    
        emit UpdateBaseValue("baseNFTAmount", _baseNFTAmount);
    }

    /**
     * @dev Sets values for {maxVotes} and {approvalVotes}.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     * 
     * Emits a {UpdateBaseValue} event with value name as `maxVotes` and value `_maxVotes`.
     * Emits a {UpdateBaseValue} event with value name as `approvalVotes` and value `_approvalVotes`.
     *
     * @param _maxVotes uint256, maximum number of votes   
     * @param _approvalVotes uint256, minimum number of votes required for approval of a Module 
     * 
     */
    function updateMaxVotes(uint256 _maxVotes, uint256 _approvalVotes) external onlyOwner{
        require(_maxVotes >= _approvalVotes, "FRTMarketplace: maxVotes should be more or equal to Approval_votes");
        maxVotes = _maxVotes;
        approvalVotes = _approvalVotes;

        emit UpdateBaseValue("maxVotes", _maxVotes);
        emit UpdateBaseValue("approvalVotes", _approvalVotes);
    }
    /******UPDATE BASE VARIABLES END******/

    /******HANDLE NFTs START******/
    
    /** 
     * @dev Creates `baseNFTAmount` copies of NFT/Module with {_tokenHash} and assigns them to `msg.sender`.
     *
     * NFT/Module will go into pending queue for voting process
     *
     * Emits a {MintNFT} event with `tokenId`, `publisher` and `_tokenHash`.
     *
     * @param _tokenHash string, IPFS CID  
     *
     */
    function mintNFT(string memory _tokenHash) external{

        uint256 newItemId = baseNFT.mint( msg.sender, _tokenHash, baseNFTAmount);

        NFTList[newItemId] = NFTStatus.Pending;
        // NFTOwners[msg.sender].push(newItemId);

        emit MintNFT(newItemId, msg.sender, _tokenHash, baseNFTAmount);
    }

    /** 
     * @dev Let user buy one copy of an approved NFT/Module.
     *
     * Requirements:
     *
     * - `_tokenId` must be a valid NFT ID, that should be approved through voting process.
     * - must have an allowance from baseNFT countract of atleast `baseNFTPrice` or more.
     * 
     * Emits a {BuyNFT} event with `tokenId` and `buyer`.
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     */
    function buyNFT(uint256 _tokenId) external {
        // require(listedNFTs[_tokenId]  == true, "FRTMarketplace: Token not listed for sale");
        require(NFTList[_tokenId]  == NFTStatus.Listed, "FRTMarketplace: Token not listed for sale");
        require(checkTokenAlowance(msg.sender) >= baseNFTPrice, "FRTMarketplace: Transfer amount exceeds allowance");
        
        address nftOwner = baseNFT.publisherOf(_tokenId);
        
        emit BuyNFT(_tokenId, msg.sender, 1);
        
        // nftOwner must have already approved this Contract to transfer his NFTs
        require(baseNFT.isApprovedForAll(nftOwner, address(this)), "FRTMarketplace: Marketplace is not allowed to transfer this NFT");
        baseNFT.safeTransferFrom(nftOwner, msg.sender, _tokenId, 1, ""); 
        
        bool transfered = baseToken.transferFrom(msg.sender, nftOwner, baseNFTPrice); // msg.sender, must have approved this Cointract to spend his coins
        require(transfered, "FRTMarketplace: transferFrom failed");

        // NFTOwners[nftOwner].push(_tokenId);
    }

    /**  
     * @dev Let user get the token URI of an NFT that he own.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of `_tokenId`.
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     */
    function downloadNFT(uint256 _tokenId) external view returns(string memory){
        require(baseNFT.balanceOf(msg.sender, _tokenId) > 0 , "FRTMarketplace: Unauthorised!");
        return baseNFT.uri(_tokenId);

    }
    /**
     * @dev Returns the number of copies of a Module/NFT with id `_tokenId` owned by `_account`.
     *
     * @param _account address, wallet address 
     * @param _tokenId uint256, Module/NFT ID  
     *
     * @return uint256, number of copies of a Module/NFT
     *
     */
    function balanceOf(address _account, uint256 _tokenId) public view returns(uint256){
        require(_account != address(0) , "FRTMarketplace: account can not be zero address!");
        return baseNFT.balanceOf(_account, _tokenId);
    }

    /**  
     * @dev Unlist an NFT to stop it's sale/purchase through Marketplace.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     *
     * Emits a {UnlistNFT} event with `tokenId`.
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     */
    function unlistNFT(uint256 _tokenId) external onlyOwner{

        NFTList[_tokenId] = NFTStatus.Unlisted;
        
        emit UnlistNFT(_tokenId);
    }

    /**  
     * @dev List an NFT to start it's sale/purchase through Marketplace.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     *
     * Emits a {ListNFT} event with `tokenId`.
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     */
    function listNFT(uint256 _tokenId) external onlyOwner{
        // TODO: check if NFT exists
        require(NFTList[_tokenId] != NFTStatus.Listed, "FRTMarketplace: NFT listed already");
        
        NFTList[_tokenId] = NFTStatus.Listed;

        emit ListNFT(_tokenId);

    }

    /******HANDLE NFTs END******/


    /******HANDLE NFTs VERIFICATION START******/

    /**  
     * @dev Let user vote for an NFT in {NFTlist} with pending status.
     *
     * Requirements:
     * 
     * - `_tokenId` must be in {NFTlist} and status should be pending
     * - User must be allowed to vote, user can use `buyNFTForTesting` method get permetion for testing
     * - User can only vote once to aany specific NFT
     *
     * @param _tokenId uint256, Module/NFT ID  
     * @param _vote bool, true for VoteUp and false for VoteDown  
     *
     */
    function voteNFT(uint256 _tokenId, bool _vote) external{
        // require(pendingNFTQueue[_tokenId], "FRTMarketplace: NFT is not in queue");
        require(NFTList[_tokenId] == NFTStatus.Pending, "FRTMarketplace: NFT is not in queue");
        require(votedAlready[_tokenId][msg.sender] == Voted.None, "FRTMarketplace: already voted for this NFT");
        require(testingAllowed[_tokenId][msg.sender] > 0 && testingAllowed[_tokenId][msg.sender] <= block.timestamp, "FRTMarketplace: not allowed to test");
        
        // TODO: force user to test a module for atleast {forceTestDuration} time
        
        if(_vote){
            NFTVotes[_tokenId].up.push(msg.sender);
            votedAlready[_tokenId][msg.sender] = Voted.Up; // to remeber if this wallet voted already

            emit VoteNFT(_tokenId, msg.sender, "Up");

        }else{
            NFTVotes[_tokenId].down.push(msg.sender);
            votedAlready[_tokenId][msg.sender] = Voted.Down; // to remeber if this wallet voted already

            emit VoteNFT(_tokenId, msg.sender, "Down");
        }
        
        voterTestingNFTs[msg.sender]--;
        refreshQueue(_tokenId);
    }

    /**  
     * @dev Checks if NFT have enough votes to get approved or rejected.
     *
     * Requirements:
     * 
     * - `_tokenId` must be in {NFTlist} and status should be pending
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     */
    function refreshQueue(uint256 _tokenId) private{
        // require(pendingNFTQueue[_tokenId] , "FRTMarketplace: NFT is not in queue");
        require(NFTList[_tokenId] == NFTStatus.Pending, "FRTMarketplace: NFT is not in queue");

        if(NFTVotes[_tokenId].up.length >= approvalVotes ){
            _approveNFT(_tokenId);

        }else if(NFTVotes[_tokenId].down.length > (maxVotes-approvalVotes)){
            _rejectNFT(_tokenId);
        }
    }

    /**  
     * @dev Approves NFT and issues rewards to publisher and voters.
     *
     * Emits an {NFTApproved} event with `_tokenId`
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     */
    function _approveNFT(uint256 _tokenId) private {

        NFTList[_tokenId] = NFTStatus.Listed;

        address publisher = baseNFT.publisherOf(_tokenId);
        string memory _tokenHash = baseNFT.getTokenURI(_tokenId);
        
        emit NFTApproved(_tokenId);

        if(!mintedURIs[_tokenHash]){
            giveReward(publisher,_tokenId);
            mintedURIs[_tokenHash] = true;
        }

        // Issue reward to majority voters
        for (uint256 i = 0; i < NFTVotes[_tokenId].up.length; ++i) {
            rewardBalance[NFTVotes[_tokenId].up[i]][_tokenId] += baseVoteReward;
        }

        // Issue refund to minority voters
        for (uint256 i = 0; i < NFTVotes[_tokenId].down.length; ++i) {
            voteRefunds[NFTVotes[_tokenId].down[i]][_tokenId] = Refund(block.timestamp + (5 minutes * voterTestingNFTs[msg.sender]), baseTestingPrice );
        }

    }

    /**  
     * @dev Rejects NFT and issues rewards to voters & burns NFT from baseNFT contract.
     *
     * Emits an {NFTRejected} event with `_tokenId`
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     */
    function _rejectNFT(uint256 _tokenId) private {
        // delete pendingNFTQueue[_tokenId];
        NFTList[_tokenId] = NFTStatus.Rejected;
        
        // give reward to majority voters
        for (uint256 i = 0; i < NFTVotes[_tokenId].down.length; ++i) {
            rewardBalance[NFTVotes[_tokenId].down[i]][_tokenId] += baseVoteReward;
        }
        
        for (uint256 i = 0; i < NFTVotes[_tokenId].up.length; ++i) {
            voteRefunds[NFTVotes[_tokenId].up[i]][_tokenId] = Refund(block.timestamp + (5 minutes * voterTestingNFTs[msg.sender]), baseTestingPrice );
        }

        address publisher = baseNFT.publisherOf(_tokenId);
        uint256 amount = baseNFT.balanceOf(publisher, _tokenId);

        emit NFTRejected(_tokenId);

        // burn NFT
        baseNFT.burn(publisher, _tokenId, amount);
    }

    /**  
     * @dev Let user buy an NFT with pending status from {NFTlist} for testing.
     *
     * Requirements:
     * 
     * - `_tokenId` must be in {NFTlist} and status should be pending
     * - msg.sender should not be the publishers of `_tokenId`
     * - must have an allowance from baseNFT countract of atleast `baseTestingPrice` or more.
     *
     * Emits a {BuyNFTForVoting} event with `tokenURI` for testing.
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     */
    function buyNFTForTesting(uint256 _tokenId) external{
        require(baseNFT.publisherOf(_tokenId) != msg.sender, "FRTMarketplace: NFT owner can't buy for vote");
        require(NFTList[_tokenId] == NFTStatus.Pending, "FRTMarketplace: NFT is not in queue");
        require(testingAllowed[_tokenId][msg.sender] == 0, "FRTMarketplace: A user can't buy an NFT twice for testing");
        // TODO: events are public so token uri will always be visible to everyone
        emit BuyNFTForVoting(_tokenId, msg.sender);

        // TODO: Q2 0.25
        // TODO: stop USERS to vote for it's own NFT
        testingAllowed[_tokenId][msg.sender] = block.timestamp + forceTestDuration;
        voterTestingNFTs[msg.sender]++; // keep a count of how many modules a user is testing

        bool transfered = baseToken.transferFrom(msg.sender, address(this), baseTestingPrice);
        require(transfered, "FRTMarketplace: transferFrom failed");
    }

    /**  
     * @dev Let user download an NFT with pending status that he baught.
     *
     * Requirements:
     * 
     * - `_tokenId` must be in {NFTlist} and status should be pending
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     * @return _uri string, token uri
     */
    function downloadNFTForTesting(uint256 _tokenId) external view returns(string memory _uri){
        require(testingAllowed[_tokenId][msg.sender] != 0, "FRTMarketplace: not allowed to download");
        require(NFTList[_tokenId] == NFTStatus.Pending, "FRTMarketplace: NFT is not in queue anymore");

        _uri = baseNFT.uri(_tokenId);
    }

    /******HANDLE NFTs VERIFICATION END******/

    /******HELPERS START******/

    /**  
     * @dev Returns the allowance of {baseToken} for this contract from {_account}.
     *
     * @param _account address, wallet address 
     *
     * @return uint256, allowance from {_account}
     *
     */
    function checkTokenAlowance(address _account) internal view returns (uint256){
        return baseToken.allowance(_account, address(this));
    }

    /**  
     * @dev Returns balance in {baseToken} of this contract.
     *
     * @return uint256, contract's blance
     *
     */
    function contractTokenBalance() external view returns(uint256){
        return baseToken.balanceOf(address(this));
    }
    
    /**  
     * @dev Lets user withdraw reward balance of a Module.
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     */
    function withdrawRewards(uint256 _tokenId) external {
        require(rewardBalance[msg.sender][_tokenId] > 0 , "FRTMarketplace: insuficiend rewards to withdraw!");

        bool transfered = baseToken.transfer(msg.sender, rewardBalance[msg.sender][_tokenId]);
        require(transfered, "FRTMarketplace: transfer failed");

        rewardBalance[msg.sender][_tokenId] = 0;

    }
    
    /**  
     * @dev Lets user withdraw refund balance of a Module.
     *
     * @param _tokenId uint256, Module/NFT ID  
     *
     */
    function withdrawRefunds(uint256 _tokenId) external {
        require(voteRefunds[msg.sender][_tokenId].amount > 0 , "FRTMarketplace: insuficiend refund amount to withdraw!");
        require(voteRefunds[msg.sender][_tokenId].time <= block.timestamp , "FRTMarketplace: not allowed to withdraw funds for now!");
        
        voteRefunds[msg.sender][_tokenId].amount = 0;

        bool transfered = baseToken.transfer(msg.sender, voteRefunds[msg.sender][_tokenId].amount);
        require(transfered, "FRTMarketplace: transfer failed");

    }
    /******HELPERS END******/

    /******REWARDS LOGIC START******/

    /**  
     * @dev Lets contract admin set the reward data for reward logic.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     *
     * @param _reward array of tuple, Reward info/settings 
     *
     */
    function setRewardsData(Reward[] memory _reward) external onlyOwner{
        for(uint256 i; i < _reward.length; i++ ){
            rewardsData[_reward[i].year] = _reward[i];
        }
    }

    /**  
     * @dev Removes the reward data of a specifuc year.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     *
     * @param _year uint256, year number or index of array 
     *
     */
    function deleteRewardsData(uint256 _year) external onlyOwner{
        delete rewardsData[_year];
    }

    /**  
     * @dev Returns if a voter is elegible to withdraw refund for a specific Module.
     *
     * Requirements:
     * 
     * - Only contract Owner can call this method
     *
     * @param _tokenId uint256, Module/NFT ID  
     * @param _voter address, voter's waller address 
     *
     * @return bool
     *
     */
    function canWithdrawRefund(address _voter ,uint256 _tokenId) external view returns(bool){
        return voteRefunds[_voter][_tokenId].time <= block.timestamp && voteRefunds[_voter][_tokenId].amount > 0;
    }

    /**  
     * @dev Sets reward for Module publisher based on time since contract was published and {rewardData}.
     *
     * @param _tokenId uint256, Module/NFT ID  
     * @param _publisher address, module publisher's waller address 
     *
     */
    function giveReward(address _publisher, uint256 _tokenId) internal {
        // TODO: handle what after 30 years, for now is will keep using 30th year's data
        // TODO: remove test values 

        uint256 _year = getCurrentRewardYear();
        if((rewardsData[_year].issuedReward + rewardsData[_year].reward) <= rewardsData[_year].maxReward && rewardsData[_year].publishedModules < rewardsData[_year].modules ){

            rewardBalance[_publisher][_tokenId] += rewardsData[_year].reward;
            rewardsData[_year].issuedReward += rewardsData[_year].reward;
            rewardsData[_year].publishedModules++;
        }
    }

    function getCurrentYearRewardData() public view returns( Reward memory _rewardData){
        uint256 _year = getCurrentRewardYear();
        _rewardData = rewardsData[_year];
    }

    function getCurrentRewardYear() public view returns(uint256 _year) {
        _year = ((block.timestamp - contractCreatedAt) / 365 days) < 30 ? ((block.timestamp - contractCreatedAt) / 365 days)+1 : 30 ; // get ongoing year since contract deployed
    }

    /**  
     * @dev Issue reward when a user install our app.
     * @dev for now it just sends {baseWelcomeReward} tokens to any {account}.
     *
     * @param account address 
     *
     */
    function giveWelcomeReward(address account) external{
        require(account != address(0), "FRTMarketplace: account can not be a zero address");
        bool transfered = baseToken.transfer(account, baseWelcomeReward);
        require(transfered, "FRTMarketplace: transfer failed");
    }
    /******REWARDS LOGIC END******/

    /******RATING LOGIC START******/
    function submitRating(uint256 _tokenId, uint8 _stars) external {
        require(_stars <=5 && _stars >0, "FRTMarketplace: invalid number of starts");
        require(NFTRatings[_tokenId][msg.sender] == 0, "FRTMarketplace: can not rate an nft twice");
        require(balanceOf(msg.sender, _tokenId) > 0, "FRTMarketplace: can not rate!");

        NFTRatings[_tokenId][msg.sender] = _stars;
        string memory _tokenHash = baseNFT.getTokenURI(_tokenId);

        emit RateNFT(_tokenId, _tokenHash, msg.sender, _stars);
    }
    
    /******RATING LOGIC END******/

    /******TO BE REMOVED CODE******/
    
    function withdrawTokens() external onlyOwner {
         bool transfered = baseToken.transfer(msg.sender, baseToken.balanceOf(address(this)));
         require(transfered, "FRTMarketplace: Failed to withdraw tokens");
    }
    /******TO BE REMOVED CODE******/
    
    // function getNftIdsByAddress(address _NFTOwner) external view returns( uint256[] memory _nfts){
    //     return NFTOwners[_NFTOwner];
    // }
    // function getNftsByAddress(address _NFTOwner) external view returns( NFTDetail[] memory){
    //     // uint perPage = 10;
    //     NFTDetail[] memory _nfts = new NFTDetail[](NFTOwners[_NFTOwner].length);

    //     if(NFTOwners[_NFTOwner].length == 0){
    //         return _nfts;
    //     }
    //     for(uint _i; _i < NFTOwners[_NFTOwner].length; _i++ ){
            
    //         _nfts[_i] = NFTDetail(
    //             NFTOwners[_NFTOwner][_i],  // nft Id
    //             NFTList[NFTOwners[_NFTOwner][_i]],  // status of nft
    //             baseNFT.balanceOf(_NFTOwner, NFTOwners[_NFTOwner][_i]) // nft blance of an address
    //         );
    //     }
    //     return _nfts;
    // }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}