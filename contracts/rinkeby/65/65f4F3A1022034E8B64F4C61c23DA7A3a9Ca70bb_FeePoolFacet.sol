// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPaymentSplitter {
    function release(address payable) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DivByNonZero {
    function divByNonZero(uint256 _num, uint256 _div) internal pure returns (uint256 result) {
        assembly {
            result := div(_num, _div)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../libraries/ERC721Lib.sol';
import '../libraries/FeePoolLib.sol';
import '../../interfaces/IPaymentSplitter.sol';
import '../interfaces/IFeePoolFacet.sol';
import '../utils/UsingDiamondSelfCall.sol';
import '../../misc/DivByNonZero.sol';

// import 'hardhat/console.sol';

contract FeePoolFacet is DivByNonZero, UsingDiamondSelfCall, IFeePoolFacet {
    uint256 private constant PRECISION = 1e18;
    address public immutable override pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function accrueRoyalties() public override returns (uint256 accruedRoyalties) {
        uint256 totalSupply = ERC721Lib.Storage().totalSupply;

        if (totalSupply == 0) return 0;

        try IPaymentSplitter(pool).release(payable(address(this))) {} catch {}

        FeePoolLib.FeePoolStorage storage s = FeePoolLib.Storage();
        uint256 lastWeiCheckpoint = s.lastWeiCheckpoint;
        uint256 currentBalance = address(this).balance;

        if (lastWeiCheckpoint >= currentBalance) return 0;

        unchecked {
            accruedRoyalties = currentBalance - lastWeiCheckpoint;
        }
        uint256 accruedWeiPerShare = s.accruedWeiPerShare + divByNonZero(accruedRoyalties * PRECISION, totalSupply);

        s.accruedWeiPerShare = accruedWeiPerShare;
        s.lastWeiCheckpoint = currentBalance;

        emit AccruedRoyalties(accruedRoyalties, accruedWeiPerShare);
    }

    function withdrawRoyalties() external override returns (uint256) {
        accrueRoyalties();
        uint256 withdrawableWei = _updateLockerFor(msg.sender);

        require(withdrawableWei > 0, 'NO_REWARD');

        FeePoolLib.FeePoolStorage storage s = FeePoolLib.Storage();
        s.lockers[msg.sender].withdrawableWei = 0;
        uint256 checkpoint = address(this).balance - withdrawableWei;
        s.lastWeiCheckpoint = checkpoint;

        (bool success, ) = msg.sender.call{ value: withdrawableWei }('');
        require(success, 'ETH_SEND_FAIL');

        emit WithdrawnRoyalties(msg.sender, withdrawableWei, checkpoint);
        return withdrawableWei;
    }

    function beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) external override onlyDiamond {
        // console.log('address(this)', address(this));
        accrueRoyalties();

        // For mint cases
        if (from != address(0)) _updateLockerFor(from);
        // For burn cases
        if (to != address(0)) _updateLockerFor(to);
    }

    /// TODO apply short circuit to avoid update if not necessary
    function _updateLockerFor(address addr) internal returns (uint256) {
        uint256 shares = ERC721Lib.Storage()._balanceOf[addr];

        FeePoolLib.FeePoolStorage storage s = FeePoolLib.Storage();

        uint256 accruedWeiPerShare = s.accruedWeiPerShare;
        uint256 debt = s.lockers[addr].debtWei;
        // console.log(addr, 'old debt', s.lockers[addr].debtWei);
        uint256 earnt = divByNonZero((accruedWeiPerShare - debt) * shares, PRECISION);
        uint256 withdrawableWei = s.lockers[addr].withdrawableWei + earnt;
        // console.log(addr, accruedWeiPerShare, debt);
        // console.log('+', earnt, 'rate: ', accruedWeiPerShare - debt);
        s.lockers[addr].debtWei = accruedWeiPerShare;
        // console.log(addr, 'new debt', s.lockers[addr].debtWei);
        s.lockers[addr].withdrawableWei = withdrawableWei;

        emit LockerUpdated(addr, earnt, debt, withdrawableWei, accruedWeiPerShare);

        return withdrawableWei;
    }

    function getCurrentFeeGlobals()
        external
        view
        override
        returns (uint256 lastWeiCheckpoint, uint256 accruedWeiPerShare)
    {
        FeePoolLib.FeePoolStorage storage s = FeePoolLib.Storage();
        return (s.lastWeiCheckpoint, s.accruedWeiPerShare);
    }

    function getLockerInfo(address addr) external view override returns (FeePoolLib.Locker memory) {
        return FeePoolLib.Storage().lockers[addr];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import { FeePoolLib } from '../libraries/FeePoolLib.sol';

interface IFeePoolFacet {
    event AccruedRoyalties(uint256 accrued, uint256 accruedWeiPerShare);
    event WithdrawnRoyalties(address indexed sender, uint256 amount, uint256 balance);
    event LockerUpdated(address indexed user, uint256 earnt, uint256 debt, uint256 withdrawableWei, uint256 newDebtWei);

    function accrueRoyalties() external returns (uint256 accruedRoyalties);

    function withdrawRoyalties() external returns (uint256);

    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function pool() external view returns (address);

    function getCurrentFeeGlobals() external view returns (uint256 lastWeiCheckpoint, uint256 accruedWeiPerShare);

    function getLockerInfo(address addr) external view returns (FeePoolLib.Locker memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ERC721Lib {
    bytes32 constant STORAGE_POSITION = keccak256('eth.rubynft.storage');

    struct ERC721Storage {
        uint256 totalSupply;
        mapping(uint256 => address) _ownerOf;
        mapping(address => uint256) _balanceOf;
        mapping(uint256 => address) getApproved;
        mapping(address => mapping(address => bool)) isApprovedForAll;
        mapping(uint256 => string) tokenUri;
    }

    function Storage() internal pure returns (ERC721Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library FeePoolLib {
    bytes32 constant STORAGE_POSITION = keccak256('eth.feepool.storage');

    struct Locker {
        uint256 debtWei;
        uint256 withdrawableWei;
    }

    struct FeePoolStorage {
        uint256 globalEarnedWei;
        uint256 lastWeiCheckpoint;
        uint256 accruedWeiPerShare;
        mapping(address => Locker) lockers;
    }

    function Storage() internal pure returns (FeePoolStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UsingDiamondSelfCall {
    modifier onlyDiamond() {
        require(msg.sender == address(this), 'Only the diamond can call this');
        _;
    }
}