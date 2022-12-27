contract Imp1_1967 {
    uint256 public val1;
    uint256 public val2;

    function add(uint256 k) public {
        val1 += k;
    }

    function add2(uint256 k) public {
        val2 += k;
    }
}