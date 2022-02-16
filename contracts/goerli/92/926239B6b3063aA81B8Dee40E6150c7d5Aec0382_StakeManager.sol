pragma solidity ^0.5.2;

import {IGovernance} from "./IGovernance.sol";

contract Governable {
    IGovernance public governance;

    constructor(address _governance) public {
        governance = IGovernance(_governance);
    }

    modifier onlyGovernance() {
        _assertGovernance();
        _;
    }

    function _assertGovernance() private view {
        require(
            msg.sender == address(governance),
            "Only governance contract is authorized"
        );
    }
}

pragma solidity ^0.5.2;


library ECVerify {
    function ecrecovery(bytes32 hash, uint[3] memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(sig)
            s := mload(add(sig, 32))
            v := byte(31, mload(add(sig, 64)))
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0x0);
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0x0);
        }

        // get address out of hash and signature
        address result = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(result != address(0x0));

        return result;
    }

    function ecrecovery(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0x0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0x0);
        }

        // get address out of hash and signature
        address result = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(result != address(0x0));

        return result;
    }

    function ecrecovery(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (address)
    {
        // get address out of hash and signature
        address result = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(result != address(0x0), "signature verification failed");

        return result;
    }

    function ecverify(bytes32 hash, bytes memory sig, address signer)
        internal
        pure
        returns (bool)
    {
        return signer == ecrecovery(hash, sig);
    }
}

pragma solidity ^0.5.2;

contract Lockable {
    bool public locked;

    modifier onlyWhenUnlocked() {
        _assertUnlocked();
        _;
    }

    function _assertUnlocked() private view {
        require(!locked, "locked");
    }

    function lock() public {
        locked = true;
    }

    function unlock() public {
        locked = false;
    }
}

pragma solidity 0.5.17;

interface IBTTCStakeManager {
    function currentValidatorSetSize() external view returns (uint256);

    function epoch() external view returns (uint256);

    function signerToValidator(address signerAddress) external view returns (uint256);
    function isValidator(uint256 validatorId) external view returns (bool);
}

pragma solidity ^0.5.2;

interface IGovernance {
    function update(address target, bytes calldata data) external;
}

pragma solidity ^0.5.2;

import {Governable} from "../governance/Governable.sol";
import {Lockable} from "./Lockable.sol";

contract GovernanceLockable is Lockable, Governable {
    constructor(address governance) public Governable(governance) {}

    function lock() public onlyGovernance {
        super.lock();
    }

    function unlock() public onlyGovernance {
        super.unlock();
    }
}

pragma solidity 0.5.17;

interface IStakeManager {

    function verifyConsensusWithSigners(bytes32 voteHash, uint256[3][] calldata sigs) external view returns (bool,address[] memory,uint256);
}

pragma solidity ^0.5.2;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        inited = true;
        
        _;
    }
}

pragma solidity 0.5.17;

import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";

import {ECVerify} from "../../../bridge/common/lib/ECVerify.sol";
import {Initializable} from "../../common/mixin/Initializable.sol";
import {IStakeManager} from "./IStakeManager.sol";
import {GovernanceLockable} from "../../../bridge/common/mixin/GovernanceLockable.sol";
import {IGovernance} from "../../../bridge/common/governance/IGovernance.sol";
import {IBTTCStakeManager} from "../IBTTCStakeManager.sol";

contract StakeManager is
    Initializable, IStakeManager, GovernanceLockable {
    using SafeMath for uint256;
    IBTTCStakeManager public bttcStakeManager;

    constructor() public GovernanceLockable(address(0x0)) {}

    function initialize(
        address _governance,
        address _bttcStakeManager
    ) external initializer {
        governance = IGovernance(_governance);
        bttcStakeManager = IBTTCStakeManager(_bttcStakeManager);
    }

    function setBttcStakeManager(address _bttcStakeManager) external onlyGovernance {
        bttcStakeManager = IBTTCStakeManager(_bttcStakeManager);
    }

    function isValidator(uint256 validatorId) public view returns (bool) {
        return bttcStakeManager.isValidator(validatorId);
    }

    function currentValidatorSetSize() public view returns (uint256){
        return bttcStakeManager.currentValidatorSetSize();
    }

    function signerToValidator(address signerAddress) public view returns (uint256){
        return bttcStakeManager.signerToValidator(signerAddress);
    }

    function epoch() external view returns (uint256){
        return bttcStakeManager.epoch();
    }

    function verifyConsensusWithSigners(
        bytes32 actionHash,
        uint256[3][] memory sigs
    ) public view returns (bool, address[] memory, uint256) {
        uint256 totalStakers = currentValidatorSetSize();
        address[] memory signerOwners = new address[](sigs.length);
        if (sigs.length < totalStakers.mul(2).div(3).add(1)) {
            return (false, signerOwners, 0);
        }
        uint256 signedCount;
        address lastAdd;

        for (uint256 i = 0; i < sigs.length; ++i) {
            address signer = ECVerify.ecrecovery(actionHash, sigs[i]);

            if (signer == lastAdd) {
                // if signer signs twice, just skip this signature
                continue;
            }

            if (signer < lastAdd) {
                // if signatures are out of order - break out, it is not possible to keep track of unsigned validators
                break;
            }

            uint256 validatorId = signerToValidator(signer);
            if (isValidator(validatorId)) {
                lastAdd = signer;
                signedCount = signedCount.add(1);
                signerOwners[i] = signer;
            }
        }
        if(signedCount >= totalStakers.mul(2).div(3).add(1)){
            return (true , signerOwners , signedCount);
        }
        return (false , signerOwners , signedCount);
    }
}

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}