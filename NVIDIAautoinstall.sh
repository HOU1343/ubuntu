#!/bin/bash

# 检测是否已安装 make、gcc、g++ 和 ssh
if ! command -v make >/dev/null 2>&1 || ! command -v vim >/dev/null 2>&1 || ! command -v gcc >/dev/null 2>&1 || ! command -v g++ >/dev/null 2>&1 || ! command -v ssh >/dev/null 2>&1; then
  echo "正在安装 make、gcc、g++ 和 ssh..."
  sudo apt-get update
  sudo apt-get install -y make gcc g++ ssh vim
else
  echo "make、gcc、g++ 和 ssh 已经安装，跳过更新和安装."
fi

# 关闭内核自动更新
sudo apt-mark hold linux-image-generic linux-headers-generic

# 关闭防火墙
sudo systemctl stop ufw
sudo systemctl disable ufw

# 检查是否存在 nouveau 模块
if lsmod | grep -q nouveau; then
    echo "存在 nouveau 模块，执行禁用操作..."
    
    # 禁用 nouveau 模块
    sudo rmmod nouveau
    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
    echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
    sudo update-initramfs -u

# 再次检查是否成功禁用 nouveau 模块
if lsmod | grep -q nouveau; then
    echo "禁用 nouveau 模块失败，请执行系统重启以使设置生效。"

    # 提示用户是否要重启
    read -p "是否立即重启系统？(输入Y确认重启): " confirm_reboot

    # 判断用户输入是否为Y，如果是，则执行重启
    if [ "$confirm_reboot" = "Y" ] || [ "$confirm_reboot" = "y" ]; then
        sudo reboot
    else
        echo "取消重启，退出脚本."
        exit 0
    fi
fi

    echo "禁用 nouveau 模块成功."
else
    echo "不存在 nouveau 模块，无需禁用."
fi

# 列出可选的驱动文件
driver_files=(NVIDIA-Linux-*.run)


# 检查是否存在驱动文件
if [ ${#driver_files[@]} -eq 0 ]; then
  echo "未找到可用的驱动文件"
  exit 1
fi

# 显示可选的驱动文件列表
echo "可选的驱动文件："
for ((i=0; i<${#driver_files[@]}; i++)); do
  echo "$(($i+1)). ${driver_files[$i]}"
done

# 提示用户选择驱动文件
echo -n "请选择要安装的驱动文件编号: "
read selection

# 检查用户选择的编号是否有效
if ! [[ $selection =~ ^[0-9]+$ ]] || [ $selection -lt 1 ] || [ $selection -gt ${#driver_files[@]} ]; then
  echo "无效的选择"
  exit 1
fi

# 获取用户选择的驱动文件名称
selected_driver=${driver_files[$(($selection-1))]}

# 为驱动文件赋予执行权限
chmod +x ./$selected_driver

# 安装选定的驱动、
# 提示用户选择安装方式
echo "请选择安装方式:"
echo "1. 默认安装"
echo "2. 交互式安装"

# 读取用户选择
echo -n "请输入选项编号: "
read install_option

# 检查用户选择的编号是否有效
if [ "$install_option" -ne 1 ] && [ "$install_option" -ne 2 ]; then
  echo "无效的选择"
  exit 1
fi

# 根据用户选择执行相应安装
if [ "$install_option" -eq 1 ]; then
  # 默认安装
  sudo ./$selected_driver --silent --no-questions --accept-license -no-x-check -no-opengl-files
else
  # 交互式安装
  sudo ./$selected_driver -no-x-check -no-opengl-files
fi

# 输出显卡信息
sudo nvidia-smi