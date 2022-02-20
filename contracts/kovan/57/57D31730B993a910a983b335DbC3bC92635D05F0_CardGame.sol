// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "Ownable.sol";
import "IERC20.sol"; // to create my own token or make available the token on smart contract
import "AggregatorV3Interface.sol"; // to get current rate of currencies
import "VRFConsumerBase.sol"; // to get randomness function

contract CardGame is VRFConsumerBase, Ownable {
    bytes32 public keyHash;
    uint256 public fee;
    event RequestedRandomness(bytes32 requestId);

    enum GAME_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    GAME_STATE public game_state;
    address public mscTokenAddress;
    IERC20 public mscToken;

    constructor(
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash,
        address _mscTokenAddress
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyHash;
        fee = _fee;
        game_state = GAME_STATE.CLOSED;
        mscTokenAddress = _mscTokenAddress;
        mscToken = IERC20(_mscTokenAddress);
    }

    // token address > player address > amount
    mapping(address => mapping(address => uint256)) public wagerOfPlayer;

    // token address > priceFeed address
    mapping(address => address) public tokenPriceFeeds;
    //address[] public players;
    // token address > player address list
    mapping(address => address[]) public players;
    address[] public allowedTokens;
    //uint256 public totalPot = 0;
    // token address > totalBetValue
    mapping(address => uint256) public totalPot;
    // token address > player address > card number
    mapping(address => mapping(address => uint256)) public playersCardNumber;
    // token > number of players
    mapping(address => uint256) public playerCounter;
    //uint256[] public cardsNumber;
    mapping(address => uint256[]) public cardNumbers;
    //address public winner = address(0); // you can't use 'null' in solidity
    // token > winner
    mapping(address => address) public winner;
    //address public tokenToRandomness = address(0);
    //player address => token addrss (to prevent to make not to people confuse when require randomness)
    address public tokenToRandomness = address(0);
    address public competedToken = address(0);
    uint256 public randomness;

    //function showMSCTokenAddress() public returns (address) {
    //return mscTokenAddress;
    //}
    //function returnPublicVariables() public view returns () {
    //return (game_state);
    //}

    function sendMSCToken(uint256 _amount) public onlyOwner {
        mscToken.transfer(msg.sender, _amount); // from contract_address to owner_address
    }

    function issueTokens(address _token) public onlyOwner {
        for (uint256 index = 0; index < players[_token].length; index++) {
            address recipient = players[_token][index];
            uint256 userTotalValue = getUserSingleTokenValue(recipient, _token);
            mscToken.transfer(recipient, userTotalValue); // send players MSCToken as a reward
        }
    }

    function allowToken(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for (uint256 index = 0; index < allowedTokens.length; index += 1) {
            if (allowedTokens[index] == _token) {
                return true;
            }
            return false;
        }
    }

    function playerIsAllowed(address _token) internal returns (bool) {
        for (uint256 index = 0; index < players[_token].length; index++) {
            address player = players[_token][index];
            if (playersCardNumber[_token][player] != 0) {
                return true;
            } else {
                return false;
            }
        }
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeeds[_token] = _priceFeed;
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = tokenPriceFeeds[_token];
        // AggregatorV3Interface is for getting current rate of currencies
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    // this func is for just calculating prices to send MSCToken to players as a reward.
    function getUserSingleTokenValue(address _user, address _token)
        internal
        returns (uint256)
    {
        if (wagerOfPlayer[_token][_user] < 0) {
            return 0;
        }

        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((wagerOfPlayer[_token][_user] * price) / (10**decimals));
    }

    // this func is for UI which each user use
    function getPlayerSingleTokenValue(address _token)
        public
        view
        returns (uint256)
    {
        if (wagerOfPlayer[_token][msg.sender] < 0) {
            return 0;
        }

        (uint256 price, uint256 decimals) = getTokenValue(_token);
        // 10 ETH (100000000000000000000)
        // ETH/USD -> 100 (10000000000)
        // 10 * 100 = 1,000
        return ((wagerOfPlayer[_token][msg.sender] * price) / (10**decimals));
    }

    //function balanceOfCG() public view returns (uint256) {
    //return address(this).balance;
    //}

    function removeFromPlayers(address _token, address _user) internal {
        uint256 index;
        for (uint256 i = 0; i < players[_token].length; i++) {
            if (players[_token][i] == _user) {
                index = i;
                break;
            }
        }
        for (uint256 e = index; e < players[_token].length - 1; e++) {
            players[_token][e] = players[_token][e + 1];
        }
        //playerCounter -= 1;
    }

    function repayBetToken(uint256 _amount, address _token) public {
        require(
            game_state == GAME_STATE.OPEN || game_state == GAME_STATE.CLOSED,
            "You can't get the refund after game started!"
        );
        require(
            wagerOfPlayer[_token][msg.sender] >= _amount,
            "You didn't bet token of the amount!"
        );
        require(
            playersCardNumber[_token][msg.sender] == 0,
            "You drew your card, you can't refund!"
        );
        IERC20(_token).transfer(msg.sender, _amount);
        wagerOfPlayer[_token][msg.sender] =
            wagerOfPlayer[_token][msg.sender] -
            _amount;
        totalPot[_token] = totalPot[_token] - _amount;
        if (wagerOfPlayer[_token][msg.sender] <= 0) {
            removeFromPlayers(_token, msg.sender);
        }
    }

    function startGame() public onlyOwner {
        require(
            game_state == GAME_STATE.CLOSED,
            "Can't start new game state yet!"
        );

        game_state = GAME_STATE.OPEN;
    }

    function betMoney(uint256 _amount, address _token) public {
        require(_amount > 0, "A bet must be more than 0");
        require(tokenIsAllowed(_token), "This token is not allowed");
        require(
            players[_token].length < 5,
            "Sorry, this game is already full. Please wait next game."
        );
        require(game_state == GAME_STATE.OPEN, "You can't bet money while ");
        //require(
        //IERC20(_token).balanceOf(msg.sender) > 0,
        //"You don't have this token!"
        //);
        //msg.sender.transfer(_amount);
        //IERC20(_token).approve(address(this), _amount);

        if (_token == mscTokenAddress) {
            mscToken.transferFrom(msg.sender, address(this), _amount); // this 'msg.sender' must be owner of MSCToken, not third party address
            //mscToken.transfer(address(this), _amount); // transfer(toAddress, amount);  sender(who call this func(this contact)) sends amount of token to toAddress
        } else {
            //IERC20(_token).transferFrom(msg.sender, address(this), _amount); // this function is avaiable only when owner of the token who gived the right this contract to handle allowance with approve function gives token to users.
            IERC20(_token).transferFrom(msg.sender, address(this), _amount); // you can't use transferFrom when user send token to this contract.
        }
        wagerOfPlayer[_token][msg.sender] =
            wagerOfPlayer[_token][msg.sender] +
            _amount;
        if (players[_token].length <= 0) {
            totalPot[_token] = _amount;
        } else {
            totalPot[_token] = totalPot[_token] + _amount;
        }
        players[_token].push(msg.sender);
        playersCardNumber[_token][msg.sender] = 0;
        //playerCounter += 1;
    }

    function drawCards(address _token) public {
        game_state = GAME_STATE.CALCULATING_WINNER;
        tokenToRandomness = _token;

        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);

        //for (uint256 i = 0; i < players[competedToken].length; i++) {
        //bytes32 requestId = requestRandomness(keyHash, fee); // let fulfillRandomness do
        //emit RequestedRandomness(requestId);
        //playerCounter += 1;
        //}
        //bytes32 requestId = requestRandomness(keyHash, fee);
        //playerCounter = 0;
    }

    // Don't use 'msg.sender' in fulfillRandomness, cause user of this function is contract
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            game_state == GAME_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        randomness = _randomness;
        uint256 cardNumber = _randomness % 14;
        if (cardNumber == 0) {
            cardNumber = 1;
        }
        address player = players[tokenToRandomness][
            playerCounter[tokenToRandomness]
        ];
        playersCardNumber[tokenToRandomness][player] = cardNumber;
        cardNumbers[tokenToRandomness].push(cardNumber);
        playerCounter[tokenToRandomness] += 1;
        //address player = players[competedToken][playerCounter];
        //playersCardNumber[player] = cardNumber;
    }

    function getWinner(address _token) public onlyOwner returns (address) {
        require(
            game_state == GAME_STATE.CALCULATING_WINNER,
            "Game is not over yet!"
        );
        require(
            competedToken == address(0),
            "Before game is not over yet, owner have to pay reward to winner!"
        );
        require(
            playerIsAllowed(_token),
            "All participants needs to draw a card!"
        );

        //for (uint256 i = 0; i < players[competedToken].length; i++) {
        //uint256 cardNumber = playersCardNumber[players[competedToken][i]];
        //cardsNumber.push(cardNumber);
        //}
        uint256 max = 0;

        for (uint256 c = 0; c < cardNumbers[_token].length; c++) {
            if (cardNumbers[_token][c] > max) {
                max = cardNumbers[_token][c];
                winner[_token] = players[_token][c];
            } else if (cardNumbers[_token][c] == max) {
                uint256 judge = max % 2;
                if (judge == 0) {
                    winner[_token] = players[_token][c];
                } else if (judge == 1) {
                    continue;
                }
            }
        }
        competedToken = _token;
        return winner[_token];
    }

    function endGame() public onlyOwner {
        require(
            game_state == GAME_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(tokenIsAllowed(competedToken), "This token is not allowed");
        require(
            winner[competedToken] != address(0),
            "Still doesn't know which player is winner"
        );
        //IERC20(_token).transfer(msg.sender, totalPot);
        IERC20(competedToken).transferFrom(
            msg.sender,
            winner[competedToken],
            totalPot[competedToken]
        ); // You can use transferFrom only when you sends tokens to user. It's impossibel the reverse
        totalPot[competedToken] = 0;
        //players = new address[];
        for (
            uint256 index = 0;
            index < players[competedToken].length;
            index++
        ) {
            address player = players[competedToken][index];
            wagerOfPlayer[competedToken][player] = 0;
            playersCardNumber[competedToken][player] = 0;
        }
        tokenToRandomness = address(0);
        playerCounter[competedToken] = 0;
        players[competedToken] = new address[](0);
        cardNumbers[competedToken] = new uint256[](0);
        winner[competedToken] = address(0);
        competedToken = address(0);
        game_state = GAME_STATE.CLOSED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "LinkTokenInterface.sol";

import "VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}