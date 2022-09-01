// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./v0.8/VRFConsumerBase.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract SweetWheelSpinTracker is VRFConsumerBase, Context, Ownable {
	using SafeMath for uint256;

	address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

	// Please confirm these addresses, and keyHash & fee in constructor
	address private constant VRFCoordinator = address(0xa555fC018435bef5A13C6c6870a9d4C11DEC329C);
	address private constant LinkToken = address(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06);
	bytes32 internal keyHash;
	uint256 internal fee;

	IERC20 public token;
	uint8 public decimalsOfToken;
	address internal developer = 0x000000000000000000000000000000000000dEaD;

	bool public isStarted = false;
	bool internal pending = false;

	uint256 public minBetAmount = 100;
	
	uint256 public burnPercentage = 1;
	uint256 public developerBonusPercentage = 1;

	// segment src generated randomly for determining segment
	// in order to stop wheel spinning.
	uint256 public segmentSrc = 0;

	// struct for a segment
	struct Segment {
		uint256 earning_rate;
		uint256 probability;
	}
	// base data for wheel segments
	// [earning rate(%), probability(%)]
	Segment[] internal segData;

	// spin result
	mapping (address => uint8) internal playerTargetSegments;
	mapping (address => uint256) internal playerEarnedAmounts;

	modifier onlyStopped() {
		require(isStarted == false, "It can be called after stopped game!");
		_;
	}

	modifier onlyStarted() {
		require(isStarted == true, "It is not started yet!");
		_;
	}

	modifier onlyIdle() {
		require(pending == false, "Not finished the previous request!");
		_;
	}

	event Notification(string message);
	
	constructor() VRFConsumerBase(VRFCoordinator, LinkToken) public {
			// Please confirm keyHash & fee, and addresses above
			keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
			fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
	}

	function setToken(address _token, uint8 _decimals) external onlyOwner() onlyStopped() {
			token = IERC20(_token);
			decimalsOfToken = _decimals;
	}

	function setMinBetAmount(uint256 _amount) external onlyOwner() onlyStopped() {
		require(_amount > 0, "It should be greater than 0!");
		minBetAmount = _amount;
	}

	function setBurnPercentage(uint256 _value) external onlyOwner() onlyStopped() {
		burnPercentage = _value;
	}

	function setDeveloperBonusPercentage(uint256 _value) external onlyOwner() onlyStopped() {
		developerBonusPercentage = _value;
	}

	function setDeveloper(address _developer) external onlyOwner() onlyStopped() {
		developer = _developer;
	}

	/**
			Request randomness
		*/
	function seedRandomSegment() internal returns (bytes32 requestId) {
		require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
		pending = true;
		return requestRandomness(keyHash, fee);
	}

	/**
			Callback used by VRF Coordinator
		*/
	function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
		// shuffle segmentSrc based on random number
		segmentSrc = uint256(keccak256(abi.encode(randomness, block.number)));
		pending = false;
	}
	
	/**
			get randomness for testing
		*/
	function getRandomness256(uint256 _request) internal view returns (uint256) {
		return uint256(keccak256(abi.encode(_request, block.number)));
	}
		
	/**
			set segment data
			array [earning_rate(%), probability(%)]
		*/
	function setSegData(uint256[][] memory data) public onlyOwner() onlyIdle() onlyStopped() {
		delete segData;
		for (uint8 i = 0; i < data.length; i++) {
				segData.push(Segment(data[i][0], data[i][1]));
		}
	}
	
	/**
			get segment data
		*/
	function getSegData() public view returns (Segment[] memory) {
		return segData;
	}

	/**
			calculate target segment index for stoping spin
		*/
	function calcTargetSegment(uint256 probability) internal view returns (uint8) {
		if (segData.length != 0) {
				uint256 sp = 1;
				for (uint8 i = 0; i < segData.length; i++) {
						if (probability >= sp && probability <= sp + segData[i].probability - 1) {
								return i;
						}

						sp += segData[i].probability;
				}
		}
		
		// in case no data or can't find the segment
		return 0xFF;
	}

	/**
			get setting data
		*/
	function getSettingData() public view returns (
		uint8,
		string memory,
		uint256,
		uint256,
		Segment[] memory) {
		return (
							decimalsOfToken, 
							token.symbol(), 
							minBetAmount, 
							token.allowance(_msgSender(), address(this)),
							segData
						);
	}

	/**
			get spin result
		*/
	function getSpinResult() public view returns (uint8, uint256) {
		return (
							playerTargetSegments[_msgSender()],
							playerEarnedAmounts[_msgSender()]
						);
	}

	/**
			stop game.
		*/
	function stopGame() public onlyOwner() {
		isStarted = false;

		emit Notification('Game stopped!');
	}

	/**
			initialize game setting
		*/
	function initializeWheelSpin(uint256[][] memory data, uint256 mba, uint8 bp) public onlyOwner() onlyStopped() {
		// set segData
		setSegData(data);

		// set others
		minBetAmount = mba;
		burnPercentage = bp;
		isStarted = true;

		// call the function for randomme
		segmentSrc = getRandomness256(uint256(block.timestamp));

		emit Notification('Initialize WheelSpin game setting!');
	}

	/**
			start spin
		*/
	function startSpin(uint256 _amount, uint256 _request) public onlyStarted() {
		require(_amount >= minBetAmount, "Not enough amount!");
		require(token.balanceOf(_msgSender()) >= _amount * (10**decimalsOfToken), "Not enough balance!");
		require(token.allowance(_msgSender(), address(this)) >= _amount * (10**decimalsOfToken), "Not allowed balance!");

		address _player = _msgSender();
		token.transferFrom(_player, address(this), _amount * (10**decimalsOfToken));
		// playerBetAmounts[_player] = _amount;
		
		// caculate the probability for determining the segment
		// in order to stop spining
		uint256 _probability = uint256((segmentSrc & 0xFFF).mod(360) + 1);
		
		segmentSrc >>= 8;
		if (segmentSrc == 0) {
				// generate random numbers again for next incoming betters
				uint256 i = uint256(uint160(address(msg.sender))) & _request;
				segmentSrc = getRandomness256(i);
		}

		uint8 ts = calcTargetSegment(_probability);
		uint256 _earning_rate = segData[ts].earning_rate;
		
		// in case free spin
		if (_earning_rate == 111) {
			// transfer to player
			token.transfer(_player, _amount * (10**decimalsOfToken));
			
			// set spin result
			playerTargetSegments[_player] = ts;
			playerEarnedAmounts[_player] = 0;
		} else {
			uint256 _payout = _amount.mul(_earning_rate).div(100);

			require(token.balanceOf(address(this)) >= _payout * (10**decimalsOfToken), "No enough contract token balance");
			
			// burn
			token.transfer(deadAddress, _payout.mul(burnPercentage).div(100) * (10**decimalsOfToken));

			// transfer to developer
			token.transfer(developer, _payout.mul(developerBonusPercentage).div(100) * (10**decimalsOfToken));
			
			// transfer to player
			token.transfer(_player, _payout.mul(100 - burnPercentage - developerBonusPercentage).div(100) * (10**decimalsOfToken));

			// set spin result
			playerTargetSegments[_player] = ts;
			playerEarnedAmounts[_player] = _payout.mul(100 - burnPercentage - developerBonusPercentage).div(100);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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
pragma solidity 0.8.3;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;


interface IERC20 {
    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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