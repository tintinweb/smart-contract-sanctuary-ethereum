// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/*
█     ▄███▄   █ ▄▄  █▄▄▄▄ ▄███▄   ▄█▄     ▄  █ ██     ▄      ▄     ▄▄▄▄▀ ████▄   ▄ ▄      ▄   
█     █▀   ▀  █   █ █  ▄▀ █▀   ▀  █▀ ▀▄  █   █ █ █     █      █ ▀▀▀ █    █   █  █   █      █  
█     ██▄▄    █▀▀▀  █▀▀▌  ██▄▄    █   ▀  ██▀▀█ █▄▄█ █   █ ██   █    █    █   █ █ ▄   █ ██   █ 
███▄  █▄   ▄▀ █     █  █  █▄   ▄▀ █▄  ▄▀ █   █ █  █ █   █ █ █  █   █     ▀████ █  █  █ █ █  █ 
    ▀ ▀███▀    █      █   ▀███▀   ▀███▀     █     █ █▄ ▄█ █  █ █  ▀             █ █ █  █  █ █ 
                ▀    ▀                     ▀     █   ▀▀▀  █   ██                 ▀ ▀   █   ██ 
                                                ▀                                             
  ▄ ▄     ▄▄▄▄▀ ▄████         ▄▄▄▄▄      ▄▄▄▄▀ ██   █  █▀ ▄█    ▄     ▄▀           .-. .-.                 
 █   █ ▀▀▀ █    █▀   ▀       █     ▀▄ ▀▀▀ █    █ █  █▄█   ██     █  ▄▀            (   |   )                 
█ ▄   █    █    █▀▀        ▄  ▀▀▀▀▄       █    █▄▄█ █▀▄   ██ ██   █ █ ▀▄        .-.:  |  ;,-.                
█  █  █   █     █           ▀▄▄▄▄▀       █     █  █ █  █  ▐█ █ █  █ █   █      (_ __`.|.'_ __)              
 █ █ █   ▀       █                      ▀         █   █    ▐ █  █ █  ███       (    ./Y\.    )                 
  ▀ ▀             ▀                              █   ▀       █   ██             `-.-' | `-.-'               
                                                                                       \ 
🌈 ☘️      +       ⌛      =       💰
Original Collection LeprechaunTown_WTF : 0x360C8A7C01fd75b00814D6282E95eafF93837F27
*/
/// @author developer's website 🐸 https://www.halfsupershop.com/ 🐸
contract LeprechaunTown_WTF_Staking is ERC20, ERC721Holder, ERC1155Holder, Ownable{
    event PrizePoolWinner(address _winner, uint256 _prize, uint256 _gold);
    event DonationMade(address _donor, uint256 _amount);

    address payable public payments;
    address public projectLeader; // Project Leader Address
    address[] public admins; // List of approved Admins

    IERC721 public parentNFT_A; //main 721 NFT contract
    IERC1155 public parentNFT_B; //main 1155 NFT contract

    mapping(uint256 => address) public tokenOwnerOf_A;
    mapping(uint256 => uint256) public tokenStakedAt_A;

    mapping(uint256 => address) public tokenOwnerOf_B;
    mapping(uint256 => uint256) public tokenStakedAt_B;

    mapping(bool => mapping(uint256 => uint256)) public tokenBonus;

    struct Batch {
        bool stakable;
        uint256 min;
        uint256 max;
        uint256 bonus;
    }
    //maximum size of batchID array is 2^256-1
    Batch[] public batchID_A;
    Batch[] public batchID_B;

    bool public pausedStake_A = true;
    bool public pausedStake_B = true;

    uint256 public total_A;
    uint256 public total_B;

    uint256 public stakedCount_A;
    uint256 public stakedCount_B;

    uint256 public limitPerSession = 10;

    uint256 public EMISSION_RATE = (4 * 10 ** decimals()) / 1 days; //rate of max 4 tokens per day(86400 seconds) 
    //math for emission rate: EMISSION_RATE * 86400 = token(s) per day
    //uint256 private initialSupply = (10000 * 10 ** decimals()); //( 10000 )starting amount to mint to treasury in WEI

    uint256 public prizeFee = 0.0005 ether;
    uint256 public prizePool;
    uint256 public winningPercentage;
    uint256[] public goldPrizes;

    uint256 public randomCounter;
    uint256 public minRange = 0;
    uint256 public maxRange = 100;
    uint256 public targetNumber;

    struct Player {
        uint lastPlay;
        uint nextPlay;
    }

    mapping(uint8 => mapping(uint256 => Player)) public players;

    constructor(address _parentNFT_A, address _parentNFT_B) ERC20("$GOLD", "$GOLD") {
        parentNFT_A = IERC721(_parentNFT_A); // on deploy this is the main NFT contract (parentNFT_A)
        parentNFT_B = IERC1155(_parentNFT_B); // on deploy this is the main NFT contract (parentNFT_B)
        //_mint(msg.sender, initialSupply);
    }

    function setCollectionTotal(bool _contract_A, uint256 _total) public onlyAdmins {
        if(_contract_A){
            total_A = _total;
        }
        else{
            total_B = _total;
        }
    }

    function createModifyBatch(bool _create, uint256 _modifyID, bool _contract_A, bool _stakable, uint256 _min, uint256 _max, uint256 _bonus) external onlyAdmins {
        require(_min <= _max, "Min must be less than or equal to Max");
        // Store batch information in a struct
        Batch memory newBatch = Batch(
            _stakable,
            _min,
            _max,
            _bonus
        );
        if(_contract_A){
            if(_create){
                batchID_A.push(newBatch);
            }
            else{
                require(batchID_A.length > 0, "No Batches To Modify");
                batchID_A[_modifyID] = newBatch;
            }
        }
        else{
            if(_create){
                batchID_B.push(newBatch);
            }
            else{
                require(batchID_B.length > 0, "No Batches To Modify");
                batchID_B[_modifyID] = newBatch;
            }
        }
    }

    function canStakeChecker(bool _contract_A, uint256 _id) public view returns(bool) {
        if(_contract_A){
            for (uint256 i = 0; i < batchID_A.length; i++) {
                if (_id >= batchID_A[i].min && _id <= batchID_A[i].max){
                    if (batchID_A[i].stakable){
                        return true;
                    }
                    else{
                        break;
                    }
                }
            }
        }
        else{
            for (uint256 i = 0; i < batchID_B.length; i++) {
                if (_id >= batchID_B[i].min && _id <= batchID_B[i].max){
                    if (batchID_B[i].stakable){
                        return true;
                    }
                    else{
                        break;
                    }
                }
            }
        }
        return false;
    }

    function getBatchBonus(bool _contract_A, uint256 _id) public view returns(uint256) {
        if(_contract_A){
            for (uint256 i = 0; i < batchID_A.length; i++) {
                if (_id >= batchID_A[i].min && _id <= batchID_A[i].max){
                    if (batchID_A[i].bonus != 0){
                        return batchID_A[i].bonus;
                    }
                    else{
                        break;
                    }
                }
            }
        }
        else{
            for (uint256 i = 0; i < batchID_B.length; i++) {
                if (_id >= batchID_B[i].min && _id <= batchID_B[i].max){
                    if (batchID_B[i].bonus != 0){
                        return batchID_B[i].bonus;
                    }
                    else{
                        break;
                    }
                }
            }
        }
        return 1;
    }

    /**
    @dev Admin can set the bonus multiplier of a ID.
    */
    function setTokenBonus(bool _contract_A, uint256 _id, uint256 _bonus) external onlyAdmins {
        tokenBonus[_contract_A][_id] = _bonus;
    }

    /**
    @dev Admin can set the limit of IDs per session.
    */
    function setLimitPerSession(uint256 _limit) external onlyAdmins {
        limitPerSession = _limit;
    }

    /**
    @dev Admin can set the EMISSION_RATE.
    */
    function setEmissionRate(uint256 _RatePerDay) external onlyAdmins {
        EMISSION_RATE = (_RatePerDay * 10 ** decimals()) / 1 days;
    }

    /**
    * @dev Admin can set the PAUSE state for contract A or B.
    * true = no staking allowed
    * false = staking allowed
    */
    function pauseStaking(bool _contract_A, bool _state) public onlyAdmins {
        if(_contract_A){
            pausedStake_A = _state;
        }
        else{
            pausedStake_B = _state;
        }
    }

    /**
    * @dev User can stake NFTs they own to earn rewards over time.
    * Note: User must set this contract as approval for all on the parentNFT contracts in order to stake NFTs.
    * This function only stakes NFT IDs from the parentNFT_A or parentNFT_B contract.
    */
    function stake(uint[] memory _tokenIDs, bool _contract_A) public {
        require(_tokenIDs.length != 0, "No IDs");
        require(_tokenIDs.length <= limitPerSession, "Too Many IDs");
        if(_tokenIDs.length == 1){
            require(canStakeChecker(_contract_A, _tokenIDs[0]), "Token Is Not Stakable");
            stakeOne(_tokenIDs[0], _contract_A);
        }
        else{
            stakeMultiple(_tokenIDs, _contract_A);
        }
    }

    function stakeOne(uint256 _tokenID, bool _contract_A) private {
        if(_contract_A){
            require(pausedStake_A != true, "Contract A Staking Paused");
            require(tokenOwnerOf_A[_tokenID] == 0x0000000000000000000000000000000000000000, "NFT ALREADY STAKED");
            parentNFT_A.safeTransferFrom(msg.sender, address(this), _tokenID);
            tokenOwnerOf_A[_tokenID] = msg.sender;
            tokenStakedAt_A[_tokenID] = block.timestamp;
            stakedCount_A++;
        }
        else{
            require(pausedStake_B != true, "Contract B Staking Paused");
            require(tokenOwnerOf_B[_tokenID] == 0x0000000000000000000000000000000000000000, "NFT ALREADY STAKED");
            parentNFT_B.safeTransferFrom(msg.sender, address(this), _tokenID, 1, "0x00");
            tokenOwnerOf_B[_tokenID] = msg.sender;
            tokenStakedAt_B[_tokenID] = block.timestamp;
            stakedCount_B++;
        }
    }

    function stakeMultiple(uint[] memory _tokenIDs, bool _contract_A) private {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            require(canStakeChecker(_contract_A, _tokenID), "Token(s) Is Not Stakable");
            stakeOne(_tokenID, _contract_A);
        }
    }

    /**
    * @dev User can check estimated rewards gained so far from an address that staked an NFT.
    * Note: The staker address must have an NFT currently staked.
    * The returned amount is calculated as Wei. 
    * Use https://etherscan.io/unitconverter for conversions or do math returnedValue / (10^18) = reward estimate.
    */
    function estimateRewards(uint[] memory _tokenIDs, bool _contract_A) public view returns (uint256) {
        uint256 timeElapsed;
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            uint256 _batchBonus = getBatchBonus(_contract_A, _tokenID);
            uint256 _calcTime;
            if (_contract_A){
                require(tokenOwnerOf_A[_tokenID] != 0x0000000000000000000000000000000000000000, "NFT NOT STAKED");
                //rewards can be set within this function based on the amount and time NFTs are staked
                _calcTime += (block.timestamp - tokenStakedAt_A[_tokenID]);
            }
            else{
                require(tokenOwnerOf_B[_tokenID] != 0x0000000000000000000000000000000000000000, "NFT NOT STAKED");
                //rewards can be set within this function based on the amount and time NFTs are staked
                _calcTime += (block.timestamp - tokenStakedAt_B[_tokenID]);
            }

            if (tokenBonus[_contract_A][_tokenID] != 0) {
                timeElapsed += _calcTime * tokenBonus[_contract_A][_tokenID];
            }
            else{
                timeElapsed += _calcTime * _batchBonus;
            }
        }

        return timeElapsed * EMISSION_RATE;
    } 

    /**
    * @dev User can unstake NFTs to earn the rewards gained over time.
    * Note: User must have a NFT already staked in order to unstake and gain rewards.
    * This function only unstakes NFT IDs that they currently have staked.
    * Rewards are calculated based on the Emission_Rate.
    */
    function unstake(uint[] memory _tokenIDs, bool _contract_A) public {
        require(_tokenIDs.length != 0, "No IDs");
        require(_tokenIDs.length <= limitPerSession, "Too Many IDs");
        require(isOwnerOfAllStaked(msg.sender, _contract_A, _tokenIDs), "CANNOT UNSTAKE");

        uint256 reward = estimateRewards(_tokenIDs, _contract_A);

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            if(_contract_A){
                parentNFT_A.safeTransferFrom(address(this), msg.sender, _tokenID);
                delete tokenOwnerOf_A[_tokenID];
                delete tokenStakedAt_A[_tokenID];
                stakedCount_A--;
            }
            else{
                parentNFT_B.safeTransferFrom(address(this), msg.sender, _tokenID, 1, "0x00");
                delete tokenOwnerOf_B[_tokenID];
                delete tokenStakedAt_B[_tokenID];
                stakedCount_B--;
            }
        }
        _mint(msg.sender, reward); // Minting the reward tokens gained for staking
    }

    /**
    * @dev Allows Owner or Project Leader to set the parentNFT contracts to a specified address.
    * WARNING: Please ensure all users NFTs are unstaked before setting a new address
    */
    function setStakingContract(bool _contract_A, address _contractAddress) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");

        if(_contract_A){
            parentNFT_A = IERC721(_contractAddress); // set the main NFT contract (parentNFT_A)
        }
        else{
            parentNFT_B = IERC1155(_contractAddress); // set the main NFT contract (parentNFT_B)
        }
    }

    /**
    * @dev Returns the owner address of a specific token staked
    * Note: If address returned is 0x0000000000000000000000000000000000000000 token is not staked.
    */
    function getTokenOwnerOf(bool _contract_A, uint256 _tokenID) public view returns(address){
        if(_contract_A){
            return tokenOwnerOf_A[_tokenID];
        }
        else{
            return tokenOwnerOf_B[_tokenID];
        }
    }

    function isOwnerOfAllStaked(address _holder, bool _contract_A, uint[] memory _tokenIDs) public view returns(bool){
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];

            if(getTokenOwnerOf(_contract_A, _tokenID) == _holder){
                //HOLDER IS TRUE
            }
            else{
                return false;
            }
        }
        return true;
    }

    /**
    * @dev Returns the unix date the token was staked
    */
    function getStakedAt(bool _contract_A, uint256 _tokenID) public view returns(uint256){
        if(_contract_A){
            return tokenStakedAt_A[_tokenID];
        }
        else{
            return tokenStakedAt_B[_tokenID];
        }
    }

    /**
    * @dev Returns the total amount of tokens staked
    */
    function getTotalStaked() public view returns(uint256){
        return stakedCount_A + stakedCount_B;
    }

    /**
    * @dev Allows Admins to mint an amount of tokens to a specified address.
    * Note: _amount must be in WEI use https://etherscan.io/unitconverter for conversions.
    */
    function mintTokens(address _to, uint256 _amount) external onlyAdmins {
        _mint(_to, _amount); // Minting Tokens
    }

    /**
    @dev Set the minimum and maximum range values.
    @param _minRange The new minimum range value.
    @param _maxRange The new maximum range value.
    */
    function setRange(uint256 _minRange, uint256 _maxRange) public onlyAdmins {
        minRange = _minRange;
        maxRange = _maxRange;
    }

    /**
    @dev Set the prize pool percentage the winner will receive.
    @param _percentage The new prize pool percentage.
    @param _prizeFee The new prize pool entry fee.
    @param _goldPrizes The new set of gold prizes.
    */
    function setPrizePercentageAndFee(uint256 _percentage, uint256 _prizeFee, uint256[] memory _goldPrizes) public onlyAdmins {
        winningPercentage = _percentage;
        prizeFee = _prizeFee;
        goldPrizes = _goldPrizes;
    }

    /**
    @dev Set the target number that will determine the winner.
    @param _targetNumber The new target number.
    */
    function setTargetNumber(uint256 _targetNumber) public onlyAdmins {
        targetNumber = _targetNumber;
    }

    //determines if user has won
    function isWinner(uint _luckyNumber) internal view returns (bool) {
        return targetNumber == randomNumber(minRange, maxRange, _luckyNumber);
    }

    //"Randomly" returns a number >= _min and <= _max.
    function randomNumber(uint _min, uint _max, uint _luckyNumber) internal view returns (uint256) {
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            randomCounter,
            _luckyNumber)
        )) % (_max + 1 - _min) + _min;
        
        return random;
    }

    /**
    @dev Allows a user to play the Lucky Spin game by providing a lucky number and the ID of an ERC721 or ERC1155 token they hold or have staked.
    If the user holds the specified token and meets the requirements for playing again, a random number is generated to determine if
    they win the prize pool and/or a gold token prize. The payout is sent to the user's address and a PrizePoolWinner event is emitted.
    If the user does not win, they still receive a gold token prize.
    @param _luckyNumber The lucky number chosen by the user to play the game.
    @param _id The ID of the ERC721 or ERC1155 token that the user holds.
    */
    function luckySpin(uint _luckyNumber, uint256 _id) public payable returns (bool) {
        (bool playable, uint8 contractID) = canPlay(_id);
        require(playable, "You can't play again yet!");
        require(_luckyNumber <= maxRange && _luckyNumber >= minRange, "Lucky Number Must Be Within Given Min Max Range");
        require(msg.value >= (prizeFee), "Insufficient Funds");
        uint256 goldPayout = goldPrizes[0];
        prizePool += prizeFee;
        bool won = false;
        if (prizePool != 0 && isWinner(_luckyNumber)) {
            // Calculate the payout as a percentage of the prize pool
            uint256 payout = (prizePool * winningPercentage) / 100;
            if (payout > 0) {
                prizePool -= payout;
                // Send the payout to the player's address
                bool success = payable(msg.sender).send(payout);
                require(success, "Failed to send payout to player");
            }
            if (goldPrizes.length > 1) {
                uint256 spin = randomNumber(1, goldPrizes.length - 1, _luckyNumber);
                goldPayout = goldPrizes[spin];
            }
            
            _mint(msg.sender, goldPayout);
            emit PrizePoolWinner(msg.sender, payout, goldPayout);
            won = true;
        }
        else{
            _mint(msg.sender, goldPayout);
        }
        randomCounter++;
        players[contractID][_id].lastPlay = block.timestamp;
        players[contractID][_id].nextPlay = block.timestamp + 1 days;
        return won;
    }

    function hasTokenBalance(uint256 _id, address _user) public view returns (uint8) {
        uint8 _contractID = 0;
        if (_id <= total_A && parentNFT_A.ownerOf(_id) == _user || getTokenOwnerOf(true, _id) == _user) {
            _contractID += 1;
        }
        if (_id <= total_B && parentNFT_B.balanceOf(_user, _id) > 0 || getTokenOwnerOf(false, _id) == _user) {
            _contractID += 2;
        }
        return _contractID;
    }

    function canPlay(uint256 _id) public view returns (bool, uint8) {
        uint8 _contractID = hasTokenBalance(_id, msg.sender);
        require(_contractID > 0, "You don't have that token");
        if (_contractID == 1){
            //contract A
            //need to add a total supply check
            require(canStakeChecker(true, _id), "Token Is Not Playable");
            return (players[1][_id].nextPlay <= block.timestamp, 1);
        }
        if (_contractID == 2){
            //contract B
            //need to add a total supply check
            require(canStakeChecker(false, _id), "Token Is Not Playable");
            return (players[2][_id].nextPlay <= block.timestamp, 2);
        }
        if (_contractID == 3){
            //contract Both
            //need to add a total supply check
            if (players[1][_id].nextPlay <= block.timestamp){
                require(canStakeChecker(true, _id), "Token Is Not Playable");
                return (true, 1);
            }
            if (players[2][_id].nextPlay <= block.timestamp){
                require(canStakeChecker(false, _id), "Token Is Not Playable");
                return (true, 2);
            }
        }

        return (false, 0);
    }

    function donateToPrizePool() public payable{
        require(msg.value > 0, "Nothing Donated");
        prizePool += msg.value;
        emit DonationMade(msg.sender, msg.value);
    }

    /**
    @dev Admin can set the payout address.
    @param _address The address must be a wallet or a payment splitter contract.
    */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
    @dev Admin can pull funds to the payout address.
    */
    function withdraw() public onlyAdmins {
        require(payments != address(0), "Admin payment address has not been set");
        uint256 payout = address(this).balance - prizePool;
        (bool success, ) = payable(payments).call{ value: payout } ("");
        require(success, "Failed to send funds to admin");
    }

    /**
    @dev Admin can pull ERC20 funds to the payout address.
    */
    function withdraw(address token, uint256 amount) public onlyAdmins {
        require(token != address(0), "Invalid token address");

        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(address(this));

        require(amount <= balance, "Insufficient balance");
        require(erc20Token.transfer(payments, amount), "Token transfer failed");
    }

    /**
    @dev Auto send funds to the payout address.
    Triggers only if funds were sent directly to this address.
    */
    receive() external payable {
        require(payments != address(0), "Pay?");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

     /**
     * @dev Throws if called by any account other than the owner or admin.
     */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner or admin.
     */
    function _checkAdmins() internal view virtual {
        require(checkIfAdmin(), "Admin Only: caller is not an admin");
    }

    function checkIfAdmin() public view returns(bool) {
        if (msg.sender == owner() || msg.sender == projectLeader){
            return true;
        }
        if(admins.length > 0){
            for (uint256 i = 0; i < admins.length; i++) {
                if(msg.sender == admins[i]){
                    return true;
                }
            }
        }
        
        // Not an Admin
        return false;
    }

    /**
     * @dev Owner and Project Leader can set the addresses as approved Admins.
     * Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
     */
    function setAdmins(address[] calldata _users) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");
        delete admins;
        admins = _users;
    }

    /**
     * @dev Owner or Project Leader can set the address as new Project Leader.
     */
    function setProjectLeader(address _user) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");
        projectLeader = _user;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}