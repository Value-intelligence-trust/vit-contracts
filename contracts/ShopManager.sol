// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./VITToken.sol";

/**
 * @title  ShopManager
 * @notice On-chain merchant registry + VIT payment processor.
 *         Platform fee: platformFeeBps (default 2.5%) deducted from each payment.
 */
contract ShopManager is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant MERCHANT_ADMIN = keccak256("MERCHANT_ADMIN");

    VITToken public immutable vit;
    address  public treasury;
    uint16   public platformFeeBps = 250;
    uint256  public nextMerchantId = 1;

    struct Merchant { address owner; string name; uint16 commissionBps; bool active; uint256 totalVolume; }

    mapping(uint256 => Merchant) public merchants;
    mapping(address => uint256)  public ownerToMerchantId;

    event MerchantRegistered (uint256 indexed merchantId, address owner, string name);
    event MerchantDeactivated(uint256 indexed merchantId);
    event PaymentProcessed   (uint256 indexed merchantId, address indexed buyer, uint256 gross, uint256 fee, uint256 net);
    event PlatformFeeUpdated (uint16 prev, uint16 next);

    constructor(address _vit, address _treasury, address admin) {
        require(_vit != address(0) && _treasury != address(0) && admin != address(0));
        vit = VITToken(_vit); treasury = _treasury;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MERCHANT_ADMIN, admin);
    }

    function registerMerchant(string calldata name, uint16 commissionBps) external whenNotPaused returns (uint256 merchantId) {
        require(bytes(name).length > 0 && commissionBps <= 2000 && ownerToMerchantId[msg.sender] == 0, "Shop: invalid");
        merchantId = nextMerchantId++;
        merchants[merchantId] = Merchant({ owner: msg.sender, name: name, commissionBps: commissionBps, active: true, totalVolume: 0 });
        ownerToMerchantId[msg.sender] = merchantId;
        emit MerchantRegistered(merchantId, msg.sender, name);
    }

    function pay(uint256 merchantId, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0 && merchants[merchantId].active, "Shop: invalid payment");
        uint256 fee = (amount * platformFeeBps) / 10_000;
        uint256 net = amount - fee;
        vit.transferFrom(msg.sender, address(this), amount);
        if (fee > 0) vit.transfer(treasury, fee);
        vit.transfer(merchants[merchantId].owner, net);
        merchants[merchantId].totalVolume += amount;
        emit PaymentProcessed(merchantId, msg.sender, amount, fee, net);
    }

    function deactivateMerchant(uint256 merchantId) external {
        require(merchants[merchantId].owner == msg.sender || hasRole(MERCHANT_ADMIN, msg.sender), "Shop: unauthorized");
        merchants[merchantId].active = false;
        emit MerchantDeactivated(merchantId);
    }

    function setPlatformFeeBps(uint16 _bps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_bps <= 1000, "Shop: fee > 10%");
        emit PlatformFeeUpdated(platformFeeBps, _bps); platformFeeBps = _bps;
    }
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }
}
