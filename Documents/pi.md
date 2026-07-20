# pi

[Pi Coding Agent](https://pi.dev/)

## Settings

- 设置模型

```sh
/model
```

- 设置思考深度

```sh
/settings
Thinking level
```

## Extensions

### 操作前让用户确认

create file `~/.pi/agent/extensions/ask-before-action.ts`

```ts
/**
 * 操作前确认扩展
 *
 * 在执行 bash 命令、写文件、编辑文件之前弹出确认框。
 * 选项：Yes（本次允许）/ No（本次拒绝）/ All - 此类操作 / All - 全部操作
 *
 * 非交互模式（-p 打印模式等）下直接拒绝。
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // session 级别的放行状态
  let allowedTypes = new Set<string>(); // 已放行的工具类型
  let allowAll = false;                 // 全部放行

  // 新 session 时重置
  pi.on("session_start", async () => {
    allowedTypes = new Set();
    allowAll = false;
  });

  pi.on("tool_call", async (event, ctx) => {
    const name = event.toolName;

    // 只拦截 bash / write / edit
    if (name !== "bash" && name !== "write" && name !== "edit") {
      return undefined;
    }

    // 已经在本次 session 中放行
    if (allowAll || allowedTypes.has(name)) {
      return undefined;
    }

    // 无 UI 模式直接拒绝
    if (!ctx.hasUI) {
      return { block: true, reason: `非交互模式不允许 ${name}` };
    }

    // 构建提示信息
    const labels: Record<string, string> = {
      bash: "🐚 执行命令",
      write: "📝 写入文件",
      edit: "✏️  编辑文件",
    };
    const detail: Record<string, string> = {
      bash: event.input.command as string,
      write: event.input.path as string,
      edit: event.input.path as string,
    };

    const choice = await ctx.ui.select(
      `${labels[name]}？\n\n  ${detail[name]}`,
      [
        "Yes",
        "No",
        "All - 此类操作（bash/write/edit）",
        "All - 全部操作",
      ],
    );

    switch (choice) {
      case "Yes":
        return undefined;
      case "No":
        return { block: true, reason: "用户取消" };
      case "All - 此类操作（bash/write/edit）":
        allowedTypes.add(name);
        return undefined;
      case "All - 全部操作":
        allowAll = true;
        return undefined;
      default:
        return { block: true, reason: "用户取消" };
    }
  });
}
```