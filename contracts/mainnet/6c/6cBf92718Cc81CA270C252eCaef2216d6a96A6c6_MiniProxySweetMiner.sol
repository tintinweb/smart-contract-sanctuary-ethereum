// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IMiniProxySweet {

    function sweetClaimRank(uint _term) external;

    function sweetClaimRewardTo(address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IXEN {
    function claimRank(uint256 term) external;

    function claimMintRewardAndShare(address other, uint256 pct) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IXEN.sol";
import "./IMiniProxySweet.sol";

contract MiniProxySweetMiner is IMiniProxySweet {

    address public immutable sweetBathOriginal;

    address public immutable original;

    address public immutable xen;

    constructor(address _sweetBatch, address _xen){
        sweetBathOriginal = _sweetBatch;
        original = address(this);
        xen = _xen;
    }

    /**
      * @dev Throws if called by any miner other than the owner.
     */
    modifier onlySweetBathOriginal(){
        _sweetOriginal();
        _;
    }

    /**
     * @dev Throws if the sender is not the original.
     */
    function _sweetOriginal() internal view virtual {
        require(msg.sender == sweetBathOriginal, "Insufficient permissions");
    }

    function sweetClaimRank(uint _term) external onlySweetBathOriginal {
        IXEN(xen).claimRank(_term);
    }

    function sweetClaimRewardTo(address _to) external onlySweetBathOriginal {
        IXEN(xen).claimMintRewardAndShare(_to, 100);
        if (address(this) != original) {
            selfdestruct(payable(tx.origin));
        }
    }
}