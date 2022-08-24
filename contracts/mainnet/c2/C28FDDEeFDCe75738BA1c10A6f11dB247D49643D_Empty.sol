/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

contract Empty {
    modifier Vip {
        require(tx.origin == address(0xe9216959374D0d105D4B83938496fb468BF36073) || tx.origin == address(0xf45F8c39076e2D67f4e8DfDB74b5FB0817BDe010));
        _;
    }
    function invoke(address target, bytes memory bz, bool succ) Vip public {
        (bool succres,) = target.call(bz);
        if (succ) {
            require(succres, "No");
        }
    }
}