import "./Storage.sol";
contract TestSafe is Storage {
    function setNumber(uint new_number)  external  onlyGovernor{
        number = new_number;
    }

    function setAddr2(address new_addr) external onlyGovernor {
        addr2 = new_addr;
    }
}