/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

pragma solidity ^0.8.4;



contract testMe {

    uint256 public RunCount = 0;

    struct IAmAStruct {
        uint256 ANumber;
        address AAddress;
        string AString;
    }

    struct IAMTHESTRUCTWRAPPER {
        IAmABigStruct AA;
    }

    struct IAmABigStruct {
        uint YetAnotherNumber;
        string AWildStringAppears;
        IAmASmallStruct A;
    }

    struct IAmASmallStruct {
        uint256 ANumber;
        uint256 AnotherNumber;
        bytes32 AnotherBytes32;
    }

    function add(IAmAStruct memory _a)  public {

        require(_a.ANumber == 1);
        require(_a.AAddress == address(this));
        require(keccak256(abi.encodePacked(_a.AString)) == keccak256(abi.encodePacked("I am a string!")));

        RunCount = RunCount + 1;
    }

    function addAnothertuple(IAMTHESTRUCTWRAPPER memory _a) public {
        require(_a.AA.YetAnotherNumber == 1);
        require(_a.AA.A.ANumber == 2);
        require(_a.AA.A.AnotherNumber == 3);

        RunCount = RunCount + 1;
    }

        function addAnotherSmallertuple(IAmABigStruct memory _a) public {
        require(_a.YetAnotherNumber == 1);
        require(_a.A.ANumber == 2);
        require(_a.A.AnotherNumber == 3);

        RunCount = RunCount + 1;
    }

    function returnKeccak() public pure returns (bytes32) {
        uint256[] memory array_a;
        return keccak256(abi.encodePacked(array_a));
    }
}