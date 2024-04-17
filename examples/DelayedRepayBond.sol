// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IBond} from "src/interfaces/IBond.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DelayedRepayBond is ERC20, Ownable, IBond {
    using SafeERC20 for IERC20;

    uint8 private immutable DECIMALS;

    /**
     * @inheritdoc IBond
     */
    address public asset;

    /**
     * @inheritdoc IBond
     */
    uint256 public totalRepaidDebt;

    /**
     * @inheritdoc IBond
     */
    mapping(address issuer => uint256 amount) public issuerRepaidDebt;

    /**
     * @inheritdoc IBond
     */
    mapping(address recipient => uint256 amount) public recipientRepaidDebt;

    /**
     * @inheritdoc IBond
     */
    mapping(address issuer => mapping(address recipient => uint256 amount)) public repaidDebt;

    /**
     * @inheritdoc IBond
     */
    uint256 public totalDebt;

    /**
     * @inheritdoc IBond
     */
    mapping(address issuer => uint256 amount) public issuerDebt;

    /**
     * @inheritdoc IBond
     */
    mapping(address recipient => uint256 amount) public recipientDebt;

    /**
     * @inheritdoc IBond
     */
    mapping(address issuer => mapping(address recipient => uint256 amount)) public debt;

    constructor(address asset_)
        ERC20(string.concat("DefaultBond_", ERC20(asset_).name()), string.concat("DB_", ERC20(asset_).symbol()))
        Ownable(msg.sender)
    {
        asset = asset_;

        DECIMALS = ERC20(asset).decimals();
    }

    function decimals() public view override returns (uint8) {
        return DECIMALS;
    }

    function mint(uint256 amount) public onlyOwner {
        if (amount == 0) {
            revert();
        }

        _mint(msg.sender, amount);
    }

    /**
     * @inheritdoc IBond
     */
    function issueDebt(address recipient, uint256 amount) external override {
        if (amount == 0) {
            revert();
        }

        _burn(msg.sender, amount);

        totalDebt += amount;
        issuerDebt[msg.sender] += amount;
        recipientDebt[recipient] += amount;
        debt[msg.sender][recipient] += amount;

        emit IssueDebt(msg.sender, recipient, amount);
    }

    function repayDebt(address issuer, address recipient, uint256 amount) external {
        if (amount == 0) {
            revert();
        }

        if (amount > debt[issuer][recipient]) {
            revert();
        }

        IERC20(asset).safeTransferFrom(msg.sender, recipient, amount);

        totalDebt -= amount;
        issuerDebt[issuer] -= amount;
        recipientDebt[recipient] -= amount;
        debt[issuer][recipient] -= amount;

        totalRepaidDebt += amount;
        issuerRepaidDebt[issuer] += amount;
        recipientRepaidDebt[recipient] += amount;
        repaidDebt[issuer][recipient] += amount;

        emit RepayDebt(issuer, recipient, amount);
    }
}