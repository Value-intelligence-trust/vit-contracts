// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title  VITToken
 * @notice Value Intelligence Trust ERC-20 — Base L2
 *
 * Roles: DEFAULT_ADMIN_ROLE | MINTER_ROLE | PAUSER_ROLE
 *
 * Features:
 *   Mintable (1B hard cap) | Burnable | Pausable
 *   EIP-2612 Permit | 1% transfer fee to treasury (configurable)
 */
contract VITToken is ERC20, ERC20Burnable, ERC20Pausable, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    uint16  public transferFeeBps = 100;
    address public treasury;
    bool    public feeEnabled = true;

    event TreasuryUpdated(address indexed prev, address indexed next);
    event TransferFeeUpdated(uint16 prev, uint16 next);
    event FeeEnabledToggled(bool enabled);

    constructor(address _treasury, address admin)
        ERC20("VIT Token", "VIT")
        ERC20Permit("VIT Token")
    {
        require(_treasury != address(0) && admin != address(0), "VIT: zero address");
        treasury = _treasury;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY, "VIT: exceeds max supply");
        _mint(to, amount);
    }

    function pause()   external onlyRole(PAUSER_ROLE) { _pause(); }
    function unpause() external onlyRole(PAUSER_ROLE) { _unpause(); }

    function setTreasury(address _t) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_t != address(0), "VIT: zero address");
        emit TreasuryUpdated(treasury, _t);
        treasury = _t;
    }

    function setTransferFeeBps(uint16 _bps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_bps <= 500, "VIT: fee > 5%");
        emit TransferFeeUpdated(transferFeeBps, _bps);
        transferFeeBps = _bps;
    }

    function setFeeEnabled(bool _e) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeEnabled = _e;
        emit FeeEnabledToggled(_e);
    }

    function _update(address from, address to, uint256 value)
        internal override(ERC20, ERC20Pausable)
    {
        if (feeEnabled && from != address(0) && to != address(0) && from != treasury && to != treasury) {
            uint256 fee = (value * transferFeeBps) / 10_000;
            if (fee > 0) { super._update(from, treasury, fee); value -= fee; }
        }
        super._update(from, to, value);
    }

    function supportsInterface(bytes4 id) public view override(ERC20, AccessControl) returns (bool) {
        return super.supportsInterface(id);
    }
}
