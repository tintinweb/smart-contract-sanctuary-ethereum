// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

// 智能租賃合約
contract SmartLeaseContract {
    /* (1) 事件 event */
    // 定義一個事件「租約簽訂」
    event WrittenContractProposed(uint256 timestamp, string ipfsHash);
    // 定義一個事件「確認租客」
    event TenantAssigned(
        uint256 timestamp,
        address tenantAddress,
        uint256 rentAmount, // 最終租金
        uint256 depositAmount
    );
    // 定義一個事件「租客簽訂」
    event TenantSigned(uint256 timestamp, address tenantAddress);
    // 定義一個事件「租客繳交押金」
    event DepositPayed(
        uint256 timestamp,
        address tenantAddress,
        uint256 amount
    );
    // 事件：提出議價(時間戳、議價者地址、議價價格、斡旋保證金)
    event NegotiationProposed(
        uint256 timestamp,
        address offerAddress,
        uint256 offerPrice,
        uint256 earnestMoney
    );

    /* (2) 資料物件 struct */
    // 租客(是一個結構 struct)
    struct Tenant {
        uint256 rentAmount;
        uint256 depositAmount;
        bool tenantHasSigned; // 租客是否簽字(租客簽字後才能繳交押金、房東才能進行確認)
        bool hasPaidDeposit;
        bool initialized;
    }
    /* (3) 狀態變數 state variables */
    // 租客 dict[address: Tenant]
    mapping(address => Tenant) public addressToTenant;
    // 租客陣列
    Tenant[] public tenants;
    // 房東地址
    address payable public landlordAddress;
    // 租戶容量
    uint8 public TENANT_CAPACITY;
    // 租金(租金牌價)
    uint256 public standardRent;
    // 租金(房客斡旋價格)
    uint256 public negotiatedRent;
    // 租金(確認金額)
    uint256 public finalRent;
    // 租約的分散哈希值(ipfs hash)(之後可以使用隨機數來產生)
    // 該數值於租約提出時設定，並且不可修改
    string public writtenContractIpfsHash;
    // 租客累積量
    uint8 public tenantOccupancy = 0;
    // 押金
    uint256 deposit;
    // 斡旋金
    uint256 earnestMoney;
    /* 暫時 */
    // 檢查 address(0) 是什麼
    address testAddress_0;

    /* (4) 建構子 constructor */
    // 注意單位是「wei」
    // 建構子(房東地址、租客容量、租金牌價)
    constructor(
        address payable _landlordAddress,
        uint8 _capacity,
        uint256 _standardRent
    ) {
        // 限制：房東地址不可為空值「address(0)」
        require(
            _landlordAddress != address(0),
            "Landlord address must not be zero!"
        );
        // 限制：容量大於0
        require(_capacity > 0, "Tenant capacity must > zero!");
        // 限制：租金牌價不可小於 0
        require(_standardRent > 0, "Standard rent must > zero!");
        // (1)房東地址
        landlordAddress = _landlordAddress;
        // (2)可容納租客容量
        TENANT_CAPACITY = _capacity;
        // (3)租金牌價
        standardRent = _standardRent;
    }

    /* (5) 裝飾器 modifier */
    // 裝飾器(5-1)：只有房客可以調用
    modifier onlyTenant() {
        // 限制：本次合約的租客已經初始化
        require(
            addressToTenant[msg.sender].initialized == true,
            "Only a tenant can invoke this functionality"
        );
        _;
    }
    // 裝飾器(5-2)：只有房東可以調用
    modifier onlyLandlord() {
        // 限制：呼叫者為房東
        require(
            msg.sender == landlordAddress,
            "Only the landlord can invoke this functionality"
        );
        _;
    }
    // 裝飾器(5-3)：租約已提出「proposed」(擬稿完成、尚未簽訂)
    modifier isContractProposed() {
        // 限制：租約已提出(=不為空)
        require(
            // 依據是否有哈希值判斷是否已提出合約
            // 加上這個值也不能修改，所以不再另外設定一個變數
            // 不是空值就代表租約已經提出
            !(isSameString(writtenContractIpfsHash, "")),
            "The written contract has not been proposed yet"
        );
        _;
    }
    // 裝飾器(5-4)：租客已簽字
    modifier tenantHasSigned() {
        require(
            // 屬性「tenantHasSigned」值為 true
            addressToTenant[msg.sender].tenantHasSigned == true,
            "Tenant must sign the contract before invoking this functionality"
        );
        _;
    }
    // 裝飾器(5-5)：不是第一個地址(意思應該是不是原本的地址，再確認一下)
    // 注意這是帶參數的裝飾器，調用時必須傳入參數(租客地址)
    modifier notZeroAddres(address addr) {
        //
        require(addr != address(0), "0th address is not allowed!");
        // 暫時加入用來檢查「address(0)」究竟是啥
        testAddress_0 = address(0);
        _;
    }

    /* (6) 函數 function */
    // 函數(6-1)：提出擬好的合約方案(外部函數、房東限定，傳入參數：合約的分散哈希值)
    function proposeWrittenContract(string calldata _writtenContractIpfsHash)
        external
        onlyLandlord
    {
        // 寫入自訂的哈希值
        writtenContractIpfsHash = _writtenContractIpfsHash;
        // 觸發事件(寫入時間、哈希值)
        emit WrittenContractProposed(block.timestamp, _writtenContractIpfsHash);
    }

    // 函數(6-2)：確認、同意租客(房東限定、租約已提出、租客地址不為空值)
    // (傳入參數：租客地址、租金、押金)
    function assignTenant(
        address _tenantAddress,
        uint256 _rentAmount,
        uint256 _depositAmount
    ) external onlyLandlord isContractProposed notZeroAddres(_tenantAddress) {
        // 條件：租客累積數量 < 容量上限 (因為每次只能同意一位租客，所以租客累積量不超過容量上限即可)
        require(
            tenantOccupancy < TENANT_CAPACITY,
            "The rental unit is fully occupied."
        );
        // 條件：租客地址不可為房東地址(防止房東惡意搶租)
        require(
            _tenantAddress != landlordAddress,
            "Landlord is not allowed to be a tenant at the same time."
        );
        // 條件：租客地址不可重複
        require(
            addressToTenant[_tenantAddress].initialized == false,
            "Duplicate tenants are not allowed."
        );
        // 加入租客：將租可加入陣列「tenants」
        tenants.push(Tenant(_rentAmount, _depositAmount, false, false, true));
        // 租客地址對應到陣列「tenants」的索引值
        addressToTenant[_tenantAddress] = tenants[tenantOccupancy];
        // 租客累積量 +1
        tenantOccupancy++;
        // 觸發事件：指定租客
        emit TenantAssigned(
            block.timestamp,
            _tenantAddress,
            _rentAmount,
            _depositAmount
        );
    }

    // 函數(6-3)：簽約(合約已提出、房客限定)
    function signContract() external onlyTenant isContractProposed {
        // 條件：租約提出，但租客尚未簽約
        require(
            // 檢查合約是否已經簽訂
            addressToTenant[msg.sender].tenantHasSigned == false,
            "The tenant has already signed the contract"
        );
        // 更新狀態：租約已經簽訂
        addressToTenant[msg.sender].tenantHasSigned = true;
        // 觸發事件：簽約
        emit TenantSigned(block.timestamp, msg.sender);
    }

    // 函數(6-4)：繳交租金(房客限定、租客已簽字)
    // 租客已簽字(tenantHasSigned)才能繳交租金
    function payDeposit() external payable onlyTenant tenantHasSigned {
        // 條件：繳交金額(depositAmount) = 合約要求金額(msg.value)
        require(
            // 押金必須大於或等於一期(月)租金
            !(finalRent > addressToTenant[msg.sender].depositAmount),
            // 原本是這樣寫，但我覺得不對
            // msg.value == addressToTenant[msg.sender].depositAmount,
            "Amount of provided deposit does not match the amount of required deposit"
        );
        // 條件：租客尚未繳交押金(false)
        require(
            addressToTenant[msg.sender].hasPaidDeposit == false,
            "The tenant has already paid the deposit"
        );
        // 更新狀態：租客繳交押金
        deposit += msg.value;
        // 更新狀態：租客是否繳交押金
        addressToTenant[msg.sender].hasPaidDeposit = true;
        // 觸發事件：繳交押金
        emit DepositPayed(block.timestamp, msg.sender, msg.value);
    }

    // 函數(6-5)：判斷兩個字串是否相同
    function isSameString(string memory string1, string memory string2)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(string1)) ==
            keccak256(abi.encodePacked(string2));
    }

    /* 我額外增加的 */
    // 函數(6-6)：提出議價 -> 需支付保證金且租約狀態「已提出」
    function offerNegotiatedRent(uint256 _offerPrice)
        external
        payable
        isContractProposed
    {
        // 我大概先寫一下邏輯
        // 提出議價不限定租客
        // 每次議價不得低於牌價90%(暫定)
        // 議價必須支付斡旋保證金10%(暫定) -> 斡旋一經確認，保證金()轉為押金(deposite)

        // 條件：議價金額不得低於牌價90%
        require(
            // 檢查議價金額是否低於牌價 90% 且不高於牌價(高於牌價不合理)
            !(((standardRent * 9) / 10) > _offerPrice &&
                !(_offerPrice > standardRent)),
            "Earnest money is less than 90% of the standard rent"
        );
        // 條件：已支付10%議價保證金
        require(
            // 檢查是否已經支付議價保證金
            !(msg.value < ((standardRent * 1) / 10)),
            "The tenant has not paid the earnest money"
        );
        // 觸發事件：提出議價
        emit NegotiationProposed(
            block.timestamp, // 議價時間
            msg.sender, // 議價人，就是發送交易的人
            _offerPrice, // 議價金額
            msg.value // 提供的金額就是保證金
        );
    }

    // 函數(6-7)：調整牌告租金 -> 只有房東可以呼叫、租約狀態「」
    function adjustStandardRent() external onlyLandlord {}
}

// 註冊租賃合約
contract SmartLeaseRegistry {
    // 定義一個事件「建立租約」
    // 在什麼時間建立了租約、租約地址、房東地址、房客數量
    event LeaseContractCreated(
        uint256 timestamp,
        address newLeaseContractAddress,
        address landlord,
        uint8 capacity
    );

    // 定義一個陣列，裡面放的是租約地址
    address[] contracts;

    // 定義一個函式，建立租約
    function createLease(uint8 _capacity) public {
        address newLeaseContract = address(
            new SmartLeaseContract(
                payable(msg.sender),
                _capacity,
                1000000000000000000
            )
        );
        // 將租約地址放入陣列
        contracts.push(newLeaseContract);
        // 觸發事件
        // 在什麼時間建立了租約、租約地址、房東地址、房客數量
        emit LeaseContractCreated(
            block.timestamp,
            newLeaseContract,
            msg.sender,
            _capacity
        );
    }

    // 定義一個函式，取得租約陣列
    function getLeases() external view returns (address[] memory) {
        return contracts;
    }

    // 定義一個函式，取得租約數量
    function getNumLeases() external view returns (uint256) {
        return contracts.length;
    }
}