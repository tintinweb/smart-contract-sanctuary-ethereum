// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

//solhint-disable
contract CurveAddressProvider {
    event NewAddressIdentifier(uint256 indexed id, address addr, string description);
    event AddressModified(uint256 indexed id, address new_address, uint256 version);
    event CommitNewAdmin(uint256 indexed deadline, address indexed admin);
    event NewAdmin(address indexed admin);

    struct AddressInfo {
        address addr;
        bool is_active;
        uint256 version;
        uint256 last_modified;
        string description;
    }

    address private registry;

    address public admin;

    uint256 public transfer_ownership_deadline;

    address public future_admin;

    uint256 private queue_length;

    mapping(uint256 => AddressInfo) public get_id_info;

    uint256 public deadline_add = 1;

    constructor(address _admin) public {
        admin = _admin;
        queue_length = 1;
        get_id_info[0].description = "Main Registry";
    }

    function get_registry() external view returns (address) {
        return registry;
    }

    function set_registry(address _registry) external {
        registry = _registry;
    }

    function set_deadline_add(uint256 _time) external {
        require(msg.sender == admin);
        deadline_add = _time;
    }

    function max_id() external view returns (uint256) {
        return queue_length - 1;
    }

    function get_address(uint256 _id) external view returns (address) {
        return get_id_info[_id].addr;
    }

    function add_new_id(address _address, string memory _description) external returns (uint256) {
        require(msg.sender == admin);
        //Skipped IsContract check

        uint256 id = queue_length;
        get_id_info[id] = AddressInfo({
            addr: _address,
            is_active: true,
            version: 1,
            last_modified: block.timestamp,
            description: _description
        });

        queue_length += 1;

        emit NewAddressIdentifier(id, _address, _description);
    }

    function set_address(uint256 _id, address _address) external returns (bool) {
        require(msg.sender == admin);
        //Skipped IsContract check
        require(queue_length > _id);

        uint256 version = get_id_info[_id].version + 1;
        get_id_info[_id].addr = _address;
        get_id_info[_id].is_active = true;
        get_id_info[_id].version = version;
        get_id_info[_id].last_modified = block.timestamp;

        if (_id == 0) registry = _address;

        emit AddressModified(_id, _address, version);
    }

    function unset_address(uint256 _id) external returns (bool) {
        require(msg.sender == admin);
        require(get_id_info[_id].is_active);

        get_id_info[_id].is_active = false;
        get_id_info[_id].addr = address(0);
        get_id_info[_id].last_modified = block.timestamp;

        if (_id == 0) registry = address(0);

        emit AddressModified(_id, address(0), get_id_info[_id].version);
    }

    function commit_transfer_ownership(address _new_admin) external returns (bool) {
        require(msg.sender == admin);
        require(transfer_ownership_deadline == 0);

        uint256 deadline = block.timestamp + deadline_add;
        transfer_ownership_deadline = deadline;
        future_admin = _new_admin;

        emit CommitNewAdmin(deadline, _new_admin);

        return true;
    }

    function apply_transfer_ownership() external returns (bool) {
        require(msg.sender == admin);
        require(transfer_ownership_deadline != 0);
        require(block.timestamp >= transfer_ownership_deadline);

        address new_admin = future_admin;
        admin = new_admin;
        transfer_ownership_deadline = 0;

        emit NewAdmin(new_admin);

        return true;
    }

    function revert_transfer_ownership() external returns (bool) {
        require(msg.sender == admin);
        transfer_ownership_deadline = 0;

        return true;
    }
}