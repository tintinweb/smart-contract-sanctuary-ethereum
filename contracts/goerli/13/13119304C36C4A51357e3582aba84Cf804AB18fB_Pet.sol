// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IPet.sol";

contract Pet is IPet {
    mapping(uint256 => address) public Owners; // 宠物所有人
    mapping(uint256 => Agreement) public Agreements; // 协议
    mapping(address => uint256) public Allowance; // 可提款额度
    mapping(address => address) public ShelterPointer; // 救助站指针

    uint256 public PetCounts; // 宠物数量
    uint256 public AgreementCounts; // 协议数量
    uint256 public ShelterCounts; // 救助站数量

    address constant GUARD = address(1); // 链表首个元素
    address public admin; // 管理员地址

    bool public locked; // 合约是否锁定

    constructor() {
        admin = msg.sender;
        ShelterPointer[GUARD] = GUARD;
    }

    modifier noReentrant() {
        require(!locked, "Pet: No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Pet: Not valid address");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Pet: Not admin.");
        _;
    }

    modifier onlyShelter() {
        require(isShelter(msg.sender), "Pet: Not shelter.");
        _;
    }

    modifier onlyOwner(uint256 id) {
        require(ownerOf(id) == msg.sender, "Pet: Not owner.");
        _;
    }

    function isShelter(
        address shelter // 判定地址
    ) public view returns (
        bool // 是否为救助站
    )
    {
        return ShelterPointer[shelter] != address(0);
    }

    function ownerOf(
        uint256 id // 宠物编号
    ) public view returns (
        address // 宠物所有人地址
    )
    {
        return Owners[id];
    }

    function addAnimal(
        address to, // 预定宠物所有人地址
        Pet calldata pet // 宠物数据
    ) public onlyShelter {
        // 限制条件： to地址不能是空地址
        require(to != address(0), "Pet: mint to the zero address.");

        // 状态变量进行缓存
        uint256 id = PetCounts;

        // 将to地址址设置为宠物所有人
        Owners[id] = to;

        // 宠物编号递增
        ++PetCounts;

        // 调用Transfer事件
        emit Transfer(msg.sender, address(0), to, id, TransferType.Register);

        // 调用PetURI事件
        emit PetURI(
            id,
            pet
        );
    }

    function setPetURI(
        uint256 id, // 宠物编号
        Pet calldata pet // 宠物新的数据
    ) public onlyOwner(id) {
        // 调用PetURI事件
        emit PetURI(
            id,
            pet
        );
    }

    function setPeopleURI(
        People calldata people // 用户新的数据
    ) public {
        // 调用PeopleURI事件
        emit PeopleURI(
            msg.sender,
            people
        );
    }

    function transferFrom(
        address from, // 宠物所有人
        address to, // 宠物新的所有人
        uint256 id, // 宠物编号
        TransferType transferType// 转移类型
    ) public onlyShelter {
        // 调用_transferFrom方法
        _transferFrom(msg.sender, from, to, id, transferType);
    }

    function _transferFrom(
        address operator, // 操作人
        address from, // 宠物所有人
        address to, // 宠物新的所有人
        uint256 id, // 宠物编号
        TransferType transferType // 转移类型
    ) private {
        //  限制条件： to地址不能是空地址
        require(to != address(0), "Pet: transfer to the zero address");

        //  限制条件： from地址必须是宠物所有人
        require(this.ownerOf(id) == from, "Pet: transfer from incorrect owner");

        // 更新宠物所有人
        Owners[id] = to;

        // 调用Transfer事件
        emit Transfer(operator, from, to, id, transferType);
    }

    function generateAgreement(
        address counterParty, // 协议对手方
        uint256 petId, // 宠物编号
        uint256 fee, // 领养费用
        string calldata URI // 协议元数据
    ) public onlyOwner(petId) onlyShelter {
        // 状态变量进行缓存
        uint256 id = AgreementCounts;
        // 实例化Agreement
        Agreement memory agreement;

        // 交易对手方A：救助站
        agreement.partyA = msg.sender;

        // 交易对手方B：领养用户
        agreement.partyB = counterParty;

        // 宠物编号
        agreement.petId = petId;

        // 领养费用
        agreement.fee = fee;

        // 协议的元数据
        agreement.URI = URI;

        // 交易对手方A签署协议
        agreement.signedByPartyA = true;

        // 将协议存入映射
        Agreements[id] = agreement;

        // 协议编号递增
        ++AgreementCounts;

        // 调用SignAgreement事件
        emit SignAgreement(
            id,
            msg.sender,
            counterParty,
            petId,
            fee,
            URI,
            true,
            false
        );
    }

    function signAgreement(
        uint256 id // 协议编号
    ) public payable {
        // 状态变量进行缓存
        Agreement storage agreement = Agreements[id];

        //检查合同状态
        // 限制条件：调用人必须是协议中的对手方B
        // 限制条件：需要保证对手方B未签署协议
        // 限制条件：往合约发送的以太币数量必须等于协议中的领养费用
        require(agreement.partyB == msg.sender, "Pet: Invalid party.");
        require(!agreement.signedByPartyB, "Pet: Already signed.");
        require(agreement.fee == msg.value, " Pet: Invalid fee.");

        // 修改对手方B签署状态
        agreement.signedByPartyB = true;

        // 修改救助站提款额度
        Allowance[agreement.partyA] += msg.value;

        // 调用_transferFrom函数
        _transferFrom(
            agreement.partyA,
            agreement.partyA,
            agreement.partyB,
            agreement.petId,
            TransferType.Adopt
        );

        // 调用SignAgreement事件
        emit SignAgreement(
            id,
            agreement.partyA,
            agreement.partyB,
            agreement.petId,
            msg.value,
            agreement.URI,
            agreement.signedByPartyA,
            true
        );
    }

    function petDaily(
        uint256 id, // 宠物编号
        string memory URI //宠物照片元数据
    ) public onlyOwner(id) {
        // 调用PetDaily事件
        emit PetDaily(msg.sender, id, URI);
    }

    function addShelter(
        address shelter // 预定救助站地址
    ) public onlyAdmin {
        // 调用_addShelter方法
        _addShelter(shelter);
    }

    function addShelterBatch(
        address[] calldata shelters // 预定救助站地址数组
    ) public onlyAdmin {
        // 限制条件：不能是空数组
        require(shelters.length > 0, "Pet: Empty array.");

        // 遍历数组并调用_addShelter方法
        for (uint256 idx = 0; idx < shelters.length; ++idx) {
            _addShelter(shelters[idx]);
        }
    }

    function _addShelter(
        address shelter // 预定救助站地址数组
    ) private validAddress(shelter) {
        // 限制条件：不能多重身份
        // 限制条件：已是救助站不能添加
        require(!(shelter == admin), "Pet: Multiple roles.");
        require(!isShelter(shelter), "Pet: Already exists.");

        // 将数据添加到链表
        // 链表长度递增
        ShelterPointer[shelter] = ShelterPointer[GUARD];
        ShelterPointer[GUARD] = shelter;
        ++ShelterCounts;

        // 调用ShelterEvent事件
        emit ShelterEvent(msg.sender, shelter, true);
    }

    function removeShelter(
        address shelter, // 将要移除救助站地址
        address preShelter // 链表前一个元素
    ) public onlyAdmin {
        // 调用_removeShelter方法
        _removeShelter(shelter, preShelter);
    }

    function removeShelterBatch(
        address[] memory shelters, // 将要移除救助站地址数组
        address[] memory preShelters // 与将要移除的救助站一一对应的链表前一个元素数组
    ) public onlyAdmin {
        // 限制条件：不能是空数组
        // 限制条件：两个数组长度必须相等
        require(shelters.length > 0, "Pet: Empty array.");
        require(
            shelters.length == preShelters.length,
            "Pet: Array length must be equal."
        );

        // 遍历数组并调用_addShelter方法
        for (uint256 idx = 0; idx < shelters.length; ++idx) {
            address shelter = shelters[idx];
            address preShelter = preShelters[idx];
            removeShelter(shelter, preShelter);
        }
    }

    function _removeShelter(
        address shelter, // 将要移除救助站地址
        address preShelter // 链表前一个元素
    ) private {
        // 限制条件：必须是救助站
        // 限制条件：必须是正确的指针
        require(isShelter(shelter), "Pet: Not exist.");
        require(ShelterPointer[preShelter] == shelter, "Pet: Invalid Pointer.");

        // 将数据从链表移除
        // 链表长度递减
        ShelterPointer[preShelter] = ShelterPointer[shelter];
        ShelterPointer[shelter] = address(0);
        --ShelterCounts;

        // 调用ShelterEvent事件
        emit ShelterEvent(msg.sender, shelter, false);
    }

    function getShelters() public view returns (address[] memory) {
        // 读取链表所有救助站
        address[] memory shelters = new address[](ShelterCounts);
        address current_address = ShelterPointer[GUARD];
        for (uint256 i = 0; current_address != GUARD; ++i) {
            shelters[i] = current_address;
            current_address = ShelterPointer[current_address];
        }
        return shelters;
    }

    function withdraw() public noReentrant {
        // 状态变量进行缓存
        uint256 bal = Allowance[msg.sender];

        // 限制条件：可提款额度必须大于0
        require(bal > 0, "Pet: Empty allowance.");

        // 提款交易
        (bool sent,) = msg.sender.call{value : bal}("");

        // 限制条件：交易失败回滚
        require(sent, "Pet: Failed to send Ether.");

        // 修改可提款额度
        Allowance[msg.sender] = 0;
    }

receive() external payable {} // 合约实现receive函数来接收以太币
}