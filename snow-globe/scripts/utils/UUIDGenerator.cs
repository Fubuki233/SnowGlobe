using Godot;
using System;

/// <summary>
/// UUID 生成器 - 提供多种 ID 生成方法
/// </summary>
public static class UUIDGenerator
{
    private static readonly Random _random = new Random();
    private static readonly string _hexChars = "0123456789abcdef";
    private static readonly string _alphanumChars = "0123456789abcdefghijklmnopqrstuvwxyz";

    /// <summary>生成标准 UUID (v4)</summary>
    public static string GenerateUuid()
    {
        var uuid = new char[36];

        for (int i = 0; i < 36; i++)
        {
            if (i == 8 || i == 13 || i == 18 || i == 23)
            {
                uuid[i] = '-';
            }
            else if (i == 14)
            {
                uuid[i] = '4';
            }
            else if (i == 19)
            {
                uuid[i] = "89ab"[_random.Next(4)];
            }
            else
            {
                uuid[i] = _hexChars[_random.Next(16)];
            }
        }

        return new string(uuid);
    }

    /// <summary>生成 16 位短 ID</summary>
    public static string GenerateShortId()
    {
        var id = new char[16];
        for (int i = 0; i < 16; i++)
        {
            id[i] = _alphanumChars[_random.Next(_alphanumChars.Length)];
        }
        return new string(id);
    }

    /// <summary>生成 6 位数字 ID</summary>
    public static string GenerateNumericId()
    {
        return (_random.Next(100000, 999999)).ToString();
    }

    /// <summary>生成带时间戳的 ID</summary>
    public static string GenerateTimestampId()
    {
        var timestamp = (long)Time.GetUnixTimeFromSystem();
        var randomSuffix = _random.Next(10000);
        return $"{timestamp}_{randomSuffix:D4}";
    }
}
