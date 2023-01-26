// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./InternalHelpers.sol";
import "./ICTF.sol";

contract EVMthroughCTFs is InternalHelpers {
    uint256 public challengeCost;

    constructor(uint256 _challengeCost) {
        challengeCost = _challengeCost;
    }

    function updateChallengeCost(uint256 _challengeCost) external onlyOwner {
        challengeCost = _challengeCost;
    }

    struct CTF {
        address ctfContract;
        uint16 weight;
    }

    CTF[] public ctfs;

    function updateCTFs(CTF[] memory _ctfs) external onlyOwner {
        uint256 numberOfExistingCTFs = ctfs.length;
        if (_ctfs.length < numberOfExistingCTFs) {
            revert CTFsQuantityDecreased();
        }
        for (uint256 i = 0; i < numberOfExistingCTFs; i++) {
            ctfs[i] = _ctfs[i];
        }
        for (uint256 i = numberOfExistingCTFs; i < _ctfs.length; i++) {
            ctfs.push(_ctfs[i]);
        }
    }

    function getAllCTFs() external view returns (CTF[] memory) {
        return ctfs;
    }

    mapping(address => uint256) public lockedValues;

    function enter() external payable {
        uint256 existingLockedValue = lockedValues[msg.sender];
        if (existingLockedValue == 0) {
            if (msg.value < 2 * challengeCost) {
                revert NotEnoughValueLocked();
            }
            lockedValues[msg.sender] = msg.value;
        } else {
            // if you have already entered, can contribute however much you want
            // but don't necessarily need to contribute to solve newly added CTFs
            lockedValues[msg.sender] = existingLockedValue + msg.value;
        }
    }

    function isStudent(address student) external view returns (bool) {
        // once lockedValues[student] becomes >0, it will never return to 0
        // because during withdraw, we leave at least 1 in the balance
        return lockedValues[student] > 0;
    }

    // the uint256 in this mapping is bitpacked. i'th bit represents
    // whether the deposit for i'th CTF has been claimed by the student
    mapping(address => uint256) public claimed;

    function withdraw(address to, uint256[] memory solvedCTFIndices) external {
        // cache ctfs in memory
        CTF[] memory cachedCTFs = ctfs;

        uint256 unclaimedWeight = 0;
        uint256 claimedCTFs = claimed[to];
        for (uint256 i = 0; i < cachedCTFs.length; i++) {
            if (!hasClaimed(claimedCTFs, i)) {
                unclaimedWeight += cachedCTFs[i].weight;
            }
        }
        if (unclaimedWeight == 0) {
            revert AlreadyClaimedEverything();
        }

        uint256 solvedWeight = 0;
        for (uint256 i = 0; i < solvedCTFIndices.length; i++) {
            uint256 solvedCTFIdx = solvedCTFIndices[i];
            CTF memory solvedCTF = cachedCTFs[solvedCTFIdx];
            if (!ICTF(solvedCTF.ctfContract).solved(to)) {
                revert CTFNotSolved(solvedCTFIdx);
            }
            if (hasClaimed(claimedCTFs, i)) {
                revert AlreadyClaimed(solvedCTFIdx);
            }
            claimedCTFs = markClaimed(claimedCTFs, i);
            solvedWeight += solvedCTF.weight;
        }
        claimed[to] = claimedCTFs;

        uint256 currentlyLocked = lockedValues[to];
        uint256 unlockedPortion = (currentlyLocked * solvedWeight) /
            unclaimedWeight;
        if (unlockedPortion == currentlyLocked) {
            // leave 1 to serve as a "boolean" that student has already entered the challenge
            unlockedPortion -= 1;
        }
        lockedValues[to] = currentlyLocked - unlockedPortion;

        uint256 unlockedForOwner = unlockedPortion / 2;
        availableToClaimByOwner += unlockedForOwner;
        _safeSend(to, unlockedPortion - unlockedForOwner);
    }

    uint256 private availableToClaimByOwner = 1;

    function withdrawOwner() external onlyOwner {
        _safeSend(_owner, availableToClaimByOwner - 1);
        availableToClaimByOwner = 1; // leave 1 for gas savings
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICTF {
    function solved(address student) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error NotOwner();
error CTFsQuantityDecreased();
error NotEnoughValueLocked();
error CTFNotSolved(uint256 ctfIndex);
error AlreadyClaimed(uint256 ctfIndex);
error AlreadyClaimedEverything();

contract InternalHelpers {
    address internal _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        if (_owner != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        _owner = _newOwner;
    }

    function markClaimed(uint256 bitpackedClaimedCTFs, uint256 ctfIdx)
        internal
        pure
        returns (uint256)
    {
        return bitpackedClaimedCTFs | (0x1 << ctfIdx);
    }

    function hasClaimed(uint256 bitpackedClaimedCTFs, uint256 ctfIdx)
        internal
        pure
        returns (bool)
    {
        return ((bitpackedClaimedCTFs >> ctfIdx) & 0x1) == 0x1;
    }

    function _safeSend(address to, uint256 amount) internal {
        bool success = payable(to).send(amount);
        if (!success) {
            WETH weth = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            weth.deposit{value: amount}();
            require(weth.transfer(to, amount), "Payment failed");
        }
    }
}

interface WETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);
}