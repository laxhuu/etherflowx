// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title EtherFlowX
 * @notice A decentralized platform for managing scheduled and automated ETH flows between users.
 */
contract EtherFlowX {

    address public admin;
    uint256 public flowCount;

    struct Flow {
        uint256 id;
        address sender;
        address[] recipients;
        uint256[] amounts;
        uint256 startTime;
        uint256 interval;      // Time in seconds between automatic disbursements
        uint256 cycles;        // Total number of cycles
        uint256 executedCycles;
        bool active;
    }

    mapping(uint256 => Flow) public flows;
    mapping(address => uint256[]) public userFlows;

    event FlowCreated(
        uint256 indexed id,
        address indexed sender,
        address[] recipients,
        uint256[] amounts,
        uint256 startTime,
        uint256 interval,
        uint256 cycles
    );
    event FlowExecuted(uint256 indexed id, uint256 cycle, address indexed recipient, uint256 amount);
    event FlowStopped(uint256 indexed id);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "EtherFlowX: NOT_ADMIN");
        _;
    }

    modifier flowExists(uint256 id) {
        require(id > 0 && id <= flowCount, "EtherFlowX: FLOW_NOT_FOUND");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice Create a new scheduled flow
    function createFlow(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 interval,
        uint256 cycles
    ) external payable returns (uint256) {
        require(recipients.length > 0 && recipients.length == amounts.length, "EtherFlowX: INVALID_INPUT");
        uint256 totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(msg.value == totalAmount * cycles, "EtherFlowX: INCORRECT_FUNDS");

        flowCount++;
        flows[flowCount] = Flow({
            id: flowCount,
            sender: msg.sender,
            recipients: recipients,
            amounts: amounts,
            startTime: block.timestamp,
            interval: interval,
            cycles: cycles,
            executedCycles: 0,
            active: true
        });

        userFlows[msg.sender].push(flowCount);
        for (uint i = 0; i < recipients.length; i++) {
            userFlows[recipients[i]].push(flowCount);
        }

        emit FlowCreated(flowCount, msg.sender, recipients, amounts, block.timestamp, interval, cycles);
        return flowCount;
    }

    /// @notice Execute the next cycle of a flow
    function executeFlow(uint256 flowId) external flowExists(flowId) {
        Flow storage f = flows[flowId];
        require(f.active, "EtherFlowX: INACTIVE_FLOW");
        require(f.executedCycles < f.cycles, "EtherFlowX: ALL_CYCLES_EXECUTED");

        uint256 nextExecution = f.startTime + f.executedCycles * f.interval;
        require(block.timestamp >= nextExecution, "EtherFlowX: TOO_EARLY");

        for (uint i = 0; i < f.recipients.length; i++) {
            payable(f.recipients[i]).transfer(f.amounts[i]);
            emit FlowExecuted(flowId, f.executedCycles + 1, f.recipients[i], f.amounts[i]);
        }

        f.executedCycles++;

        if (f.executedCycles >= f.cycles) {
            f.active = false;
            emit FlowStopped(flowId);
        }
    }

    /// @notice Stop a flow prematurely (only sender or admin)
    function stopFlow(uint256 flowId) external flowExists(flowId) {
        Flow storage f = flows[flowId];
        require(f.active, "EtherFlowX: ALREADY_STOPPED");
        require(msg.sender == f.sender || msg.sender == admin, "EtherFlowX: UNAUTHORIZED");

        f.active = false;
        emit FlowStopped(flowId);
    }

    /// @notice Get flow info
    function getFlow(uint256 id) external view flowExists(id) returns (Flow memory) {
        return flows[id];
    }

    /// @notice Get all flows for a user
    function getUserFlows(address user) external view returns (uint256[] memory) {
        return userFlows[user];
    }

    /// @notice Change admin
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "EtherFlowX: ZERO_ADMIN");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }
}
