pragma solidity >0.5.13;

interface orityLike {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) external view returns (bool);
}

contract DssProxy {
    address public owner;
    address public ority;

    event SetOwner(address indexed owner);
    event Setority(address indexed ority);

    constructor(address owner_) public {
        owner = owner_;
        emit SetOwner(owner_);
    }

    receive() external payable {}

    function setOwner(address owner_) external {
        owner = owner_;
        emit SetOwner(owner_);
    }

    function setority(address ority_) external {
        ority = ority_;
        emit Setority(ority_);
    }

    function execute(address target_, bytes memory data_)
        external
        payable
        returns (bytes memory response)
    {
        require(target_ != address(0), "DssProxy/target-address-required");

        assembly {
            let succeeded := delegatecall(
                gas(),
                target_,
                add(data_, 0x20),
                mload(data_),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch succeeded
            case 0 {
                revert(add(response, 0x20), size)
            }
        }
    }
}