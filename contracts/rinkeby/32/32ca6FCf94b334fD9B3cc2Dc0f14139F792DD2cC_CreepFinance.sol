/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT

// dev address is 0xEaC458B2F78b8cb37c9471A9A0723b4Aa6b4c62D

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File @openzeppelin/contracts/security/[email protected]

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

// File @api3/airnode-protocol/contracts/rrp/interfaces/[email protected]

pragma solidity ^0.8.0;

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// File @api3/airnode-protocol/contracts/rrp/interfaces/[email protected]

pragma solidity ^0.8.0;

interface ITemplateUtilsV0 {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// File @api3/airnode-protocol/contracts/rrp/interfaces/[email protected]

pragma solidity ^0.8.0;

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}

// File @api3/airnode-protocol/contracts/rrp/interfaces/[email protected]

pragma solidity ^0.8.0;

interface IAirnodeRrpV0 is
    IAuthorizationUtilsV0,
    ITemplateUtilsV0,
    IWithdrawalUtilsV0
{
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// File @api3/airnode-protocol/contracts/rrp/requesters/[email protected]

pragma solidity ^0.8.0;

/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}

// File contracts/CreepFinance.sol

pragma solidity ^0.8.0;

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

contract CreepFinance is ReentrancyGuard, RrpRequesterV0 {
    uint256 public fee = 5; // 5% fee for 2% burning, 1% gas(0.1 % for odd one), 2% team
    uint256 public poolSize;
    uint256 public period = 1 hours;
    address public owner;
    address public teamWallet = 0x473A838fefc899f548c91bFfCFb35602060cf767;
    address public treasuryWallet = 0x09c312b1B1565bEa9e8D7ac80Dc8cAAD07F4f74f;
    address public devWallet = 0xEaC458B2F78b8cb37c9471A9A0723b4Aa6b4c62D;
    address public virtualFTMaddress =
        0x0000000000000000000000000000000000000000;

    // These can be set using setRequestParameters())
    address public airnode;
    address public sponsorWallet;
    bytes32 public endpointIdUint256;

    struct Pool {
        address tokenAddress;
        uint256 tokenAmount;
        uint256 createdIndex;
        bool burning;
        mapping(address => uint256[]) rounds;
        mapping(uint256 => address[]) players;
    }

    struct Burn {
        uint256 lastBurnt;
        uint256 totalBurnt;
    }

    struct Random {
        bytes32 value;
        uint256 timestamp;
    }

    struct Balance {
        uint256 lastUpdatedRound;
        uint256 depositAmount;
        uint256 withdrawAmount;
    }

    mapping(uint256 => Pool) public pools;
    mapping(bytes32 => bool) public expectingRequestWithIdToBeFulfilled;
    mapping(address => mapping(address => Balance)) private userBalance;
    mapping(address => Burn) public burns;
    mapping(address => uint256) private devClaimed;
    mapping(address => uint256) private teamClaimed;
    mapping(address => uint256) private treasuryClaimed;
    mapping(address => bool) public whitelist;

    Random[] public randoms;

    constructor(address _airnodeRrp) RrpRequesterV0(_airnodeRrp) {
        owner = msg.sender;
        randoms.push(
            Random(
                keccak256(abi.encodePacked(block.timestamp)),
                block.timestamp
            )
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == teamWallet, "Only Team");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == treasuryWallet, "Only Treasury");
        _;
    }

    modifier onlyDev() {
        require(msg.sender == devWallet, "Only dev");
        _;
    }

    modifier pokeMe() {
        require(
            msg.sender == owner ||
                msg.sender == teamWallet ||
                msg.sender == treasuryWallet ||
                msg.sender == devWallet ||
                whitelist[msg.sender],
            "not whitelisted"
        );
        _;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee < 5, "exceed limit");
        require(_fee > 2, "minimum fee");
        fee = _fee;
    }

    function transferOwnership(address _new) external onlyOwner {
        owner = _new;
    }

    function setteamWallet(address _new) external onlyTeam {
        teamWallet = _new;
    }

    function setTreasuryWallet(address _new) external onlyTreasury {
        treasuryWallet = _new;
    }

    function setDevWallet(address _new) external onlyDev {
        devWallet = _new;
    }

    function setWhitelist(address _new, bool flag) external onlyOwner {
        whitelist[_new] = flag;
    }

    // Set parameters used by airnodeRrp.makeFullRequest(...)
    // See makeRequestUint256()
    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        address _sponsorWallet
    ) external onlyOwner {
        // Normally, this function should be protected, as in:
        // require(msg.sender == owner, "Sender not owner");
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }

    function checker() public view returns (bool) {
        if (block.timestamp < randoms[randoms.length - 1].timestamp + period)
            return false;
        bool flag = false;
        for (uint256 i = 1; i <= poolSize; i++) {
            if (
                pools[i]
                    .players[randoms.length - pools[i].createdIndex + 1]
                    .length > 1
            ) flag = true;
        }
        return flag;
    }

    // Calls the AirnodeRrp contract with a request
    // airnodeRrp.makeFullRequest() returns a requestId to hold onto.
    function draw() external pokeMe {
        bool flag = false;
        for (uint256 i = 1; i <= poolSize; i++) {
            if (
                pools[i]
                    .players[randoms.length - pools[i].createdIndex + 1]
                    .length > 1
            ) flag = true;
        }
        if (!flag) {
            randoms.push(
                Random(randoms[randoms.length - 1].value, block.timestamp)
            );
            return;
        }
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256.selector,
            ""
        );
        // Store the requestId
        expectingRequestWithIdToBeFulfilled[requestId] = true;
    }

    // AirnodeRrp will call back with a response
    function fulfillUint256(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        // Verify the requestId exists
        require(
            expectingRequestWithIdToBeFulfilled[requestId],
            "Request ID not known"
        );
        expectingRequestWithIdToBeFulfilled[requestId] = false;
        randoms.push(
            Random(keccak256(abi.encodePacked(data)), block.timestamp)
        );
    }

    function addPool(
        address _tokenAddress,
        uint256 _tokenAmount,
        bool _burning
    ) external onlyOwner {
        poolSize++;
        pools[poolSize].tokenAddress = _tokenAddress;
        pools[poolSize].tokenAmount = _tokenAmount;
        pools[poolSize].createdIndex = randoms.length;
        pools[poolSize].burning = _burning;
    }

    function updatePeriod(uint256 _period) external onlyOwner {
        period = _period;
    }

    function getCurrentRound(uint256 index) external view returns (uint256) {
        return randoms.length - pools[index].createdIndex + 1;
    }

    function getCurrentStartTime() external view returns (uint256) {
        return randoms[randoms.length - 1].timestamp;
    }

    function getUserBalance(address _user, address _tokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 won;
        uint256 lost;
        for (uint256 i = 1; i <= poolSize; i++) {
            if (pools[i].tokenAddress != _tokenAddress) continue;
            address[] memory players;
            for (uint256 j = 0; j < pools[i].rounds[_user].length; j++) {
                uint256 round = pools[i].rounds[_user][j];
                if (randoms.length - pools[i].createdIndex + 1 == round) {
                    lost += pools[i].tokenAmount;
                    continue;
                }

                if (pools[i].players[round].length == 1) continue;

                players = getWinners(i, round);
                bool odd = players.length % 2 == 1;
                uint256 half = (players.length - (players.length % 2)) / 2;
                for (uint256 k = 0; k < players.length; k++) {
                    if (players[k] == _user) {
                        if (odd && k == half)
                            won += (pools[i].tokenAmount * fee * half) / 2500;
                        else if (k < half)
                            won += (pools[i].tokenAmount * (100 - fee)) / 100;
                        else lost += pools[i].tokenAmount;
                    }
                }
            }
        }
        uint256 reward = userBalance[_user][_tokenAddress].depositAmount +
            won -
            lost -
            userBalance[_user][_tokenAddress].withdrawAmount;

        return reward;
    }

    function getFee(address _tokenAddress) internal view returns (uint256) {
        uint256 reward;
        for (uint256 i = 1; i <= poolSize; i++) {
            if (pools[i].tokenAddress != _tokenAddress) continue;
            uint256 round = randoms.length - pools[i].createdIndex + 1;
            for (uint256 j = 1; j < round; j++) {
                uint256 count = pools[i].players[j].length;
                reward +=
                    ((pools[i].tokenAmount * (count - (count % 2))) * fee) /
                    1000;
            }
        }
        return reward;
    }

    function getTeamBalance(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        return getFee(_tokenAddress) - teamClaimed[_tokenAddress];
    }

    function getTreasuryBalance(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 reward;
        for (uint256 i = 1; i <= poolSize; i++) {
            if (pools[i].tokenAddress != _tokenAddress) continue;
            uint256 round = randoms.length - pools[i].createdIndex + 1;
            for (uint256 j = 1; j < round; j++) {
                uint256 count = pools[i].players[j].length;
                uint256 distribution = ((pools[i].tokenAmount *
                    (count - (count % 2))) * fee) / 1000;
                reward += distribution;
                if (!pools[i].burning) reward += 2 * distribution;
                if (count % 2 == 1) reward -= distribution / 5;
            }
        }
        return reward - treasuryClaimed[_tokenAddress];
    }

    function getDevBalance(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        return getFee(_tokenAddress) - devClaimed[_tokenAddress];
    }

    function getBurnBalance(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 reward;
        for (uint256 i = 1; i <= poolSize; i++) {
            if (pools[i].tokenAddress != _tokenAddress) continue;
            if (!pools[i].burning) continue;
            uint256 round = randoms.length - pools[i].createdIndex + 1;
            for (uint256 j = 1; j < round; j++) {
                uint256 count = pools[i].players[j].length;
                uint256 distribution = ((pools[i].tokenAmount *
                    (count - (count % 2))) * fee) / 1000;
                reward += 2 * distribution;
            }
        }
        return reward - burns[_tokenAddress].totalBurnt;
    }

    function getTokenAddress() public view returns (address[] memory) {
        uint256 uniqueCount;
        address[] memory data = new address[](poolSize);
        for (uint256 i = 1; i <= poolSize; i++) {
            bool check;
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (data[j] == pools[i].tokenAddress) {
                    check = true;
                    break;
                }
            }
            if (check) continue;
            data[uniqueCount] = pools[i].tokenAddress;
            uniqueCount++;
        }

        address[] memory unique = new address[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; i++) {
            unique[i] = data[i];
        }
        return unique;
    }

    function getPlayers(uint256 index, uint256 round)
        public
        view
        returns (address[] memory)
    {
        return pools[index].players[round];
    }

    function getWinners(uint256 index, uint256 round)
        internal
        view
        returns (address[] memory)
    {
        address[] memory players = getPlayers(index, round);
        uint256 half = (players.length + (players.length % 2)) / 2;

        for (uint256 i = 0; i < half; i++) {
            address player = players[i];
            uint256 swap = (uint256(
                keccak256(
                    abi.encodePacked(
                        randoms[round + pools[index].createdIndex - 1].value,
                        i,
                        players
                    )
                )
            ) % (players.length - i)) + i;
            players[i] = players[swap];
            players[swap] = player;
        }

        return players;
    }

    function validRound(uint256 index, uint256 round)
        internal
        view
        returns (bool)
    {
        if (round == 0) return false;
        if (round > randoms.length - pools[index].createdIndex + 1)
            return false;
        return true;
    }

    function winners(uint256 index, uint256 round)
        external
        view
        returns (address[] memory)
    {
        address[] memory players;
        if (validRound(index, round)) players = getWinners(index, round);
        uint256 half = (players.length - (players.length % 2)) / 2;
        address[] memory _winners = new address[](half);
        for (uint256 i = 0; i < half; i++) {
            _winners[i] = players[i];
        }
        return _winners;
    }

    function losers(uint256 index, uint256 round)
        external
        view
        returns (address[] memory)
    {
        address[] memory players;
        if (validRound(index, round)) players = getWinners(index, round);
        uint256 half = (players.length - (players.length % 2)) / 2;
        address[] memory _losers = new address[](half);
        for (uint256 i = 0; i < half; i++) {
            _losers[i] = players[players.length - 1 - i];
        }
        return _losers;
    }

    function lucky(uint256 index, uint256 round)
        external
        view
        returns (bool, address)
    {
        address[] memory players;
        if (validRound(index, round)) players = getWinners(index, round);
        uint256 half = (players.length + (players.length % 2)) / 2;
        bool odd = players.length % 2 == 1;
        if (odd) return (odd, players[half]);
        else return (odd, treasuryWallet);
    }

    function enter(uint256 index) external {
        require(index != 0, "not exiting pool");
        require(index <= poolSize, "not exiting pool");

        uint256 round = randoms.length - pools[index].createdIndex + 1;

        for (uint256 i = 0; i < pools[index].players[round].length; i++) {
            require(
                msg.sender != pools[index].players[round][i],
                "double enter"
            );
        }

        require(
            getUserBalance(msg.sender, pools[index].tokenAddress) >=
                pools[index].tokenAmount,
            "Not enough balance"
        );

        pools[index].players[round].push(msg.sender);
        pools[index].rounds[msg.sender].push(round);
    }

    function depositToken(address _tokenAddress, uint256 _amount) external {
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        userBalance[msg.sender][_tokenAddress].depositAmount += _amount;
    }

    function deposit() external payable {
        userBalance[msg.sender][virtualFTMaddress].depositAmount += msg.value;
    }

    function _transfer(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) internal {
        if (_tokenAddress != virtualFTMaddress)
            IERC20(_tokenAddress).transfer(_to, _amount);
        else {
            (bool sent, ) = _to.call{value: _amount}("");
            require(sent, "Ether not sent");
        }
    }

    function withdraw(address _tokenAddress, uint256 _amount)
        external
        nonReentrant
    {
        require(
            getUserBalance(msg.sender, _tokenAddress) >= _amount,
            "exceed amount"
        );
        userBalance[msg.sender][_tokenAddress].withdrawAmount += _amount;
        _transfer(_tokenAddress, msg.sender, _amount);
    }

    function withdrawAllFund() external nonReentrant {
        address[] memory unique = getTokenAddress();
        bool flag;
        for (uint256 i = 0; i < unique.length; i++) {
            address _tokenAddress = unique[i];
            uint256 _amount = getUserBalance(msg.sender, _tokenAddress);
            userBalance[msg.sender][_tokenAddress].withdrawAmount += _amount;
            if (_amount >= 0) {
                flag = true;
                _transfer(_tokenAddress, msg.sender, _amount);
            }
        }
        require(flag, "zero balance");
    }

    function claimTeam(address _tokenAddress, uint256 _amount)
        external
        onlyTeam
        nonReentrant
    {
        require(getTeamBalance(_tokenAddress) >= _amount, "exceed amount");
        teamClaimed[_tokenAddress] += _amount;
        _transfer(_tokenAddress, msg.sender, _amount);
    }

    function claimTreasury(address _tokenAddress, uint256 _amount)
        external
        onlyTreasury
        nonReentrant
    {
        require(getTreasuryBalance(_tokenAddress) >= _amount, "exceed amount");
        treasuryClaimed[_tokenAddress] += _amount;
        _transfer(_tokenAddress, msg.sender, _amount);
    }

    function claimDev(address _tokenAddress, uint256 _amount)
        external
        onlyDev
        nonReentrant
    {
        require(getDevBalance(_tokenAddress) >= _amount, "exceed amount");
        devClaimed[_tokenAddress] += _amount;
        _transfer(_tokenAddress, msg.sender, _amount);
    }

    function claimTeamAll() external onlyTeam nonReentrant {
        address[] memory unique = getTokenAddress();
        bool flag;
        for (uint256 i = 0; i < unique.length; i++) {
            address _tokenAddress = unique[i];
            uint256 _amount = getTeamBalance(_tokenAddress);
            teamClaimed[_tokenAddress] += _amount;
            if (_amount >= 0) {
                flag = true;
                _transfer(_tokenAddress, msg.sender, _amount);
            }
        }
        require(flag, "zero balance");
    }

    function claimTreasuryAll() external onlyTreasury nonReentrant {
        address[] memory unique = getTokenAddress();
        bool flag;
        for (uint256 i = 0; i < unique.length; i++) {
            address _tokenAddress = unique[i];
            uint256 _amount = getTreasuryBalance(_tokenAddress);
            treasuryClaimed[_tokenAddress] += _amount;
            if (_amount >= 0) {
                flag = true;
                _transfer(_tokenAddress, msg.sender, _amount);
            }
        }
        require(flag, "zero balance");
    }

    function claimDevAll() external onlyDev nonReentrant {
        address[] memory unique = getTokenAddress();
        bool flag;
        for (uint256 i = 0; i < unique.length; i++) {
            address _tokenAddress = unique[i];
            uint256 _amount = getDevBalance(_tokenAddress);
            devClaimed[_tokenAddress] += _amount;
            if (_amount >= 0) {
                flag = true;
                _transfer(_tokenAddress, msg.sender, _amount);
            }
        }
        require(flag, "zero balance");
    }

    function burn() external onlyOwner nonReentrant {
        bool flag = false;
        address[] memory unique = getTokenAddress();
        for (uint256 i = 0; i < unique.length; i++) {
            address _tokenAddress = unique[i];
            uint256 toBurn = getBurnBalance(_tokenAddress);
            if (toBurn <= 0) continue;
            flag = true;
            burns[_tokenAddress].lastBurnt = toBurn;
            burns[_tokenAddress].totalBurnt += toBurn;
            IERC20Burnable(_tokenAddress).burn(burns[_tokenAddress].lastBurnt);
        }
        require(flag, "nothing to burn");
    }
}