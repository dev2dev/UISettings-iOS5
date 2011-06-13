#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#import <mach/mach.h> 
#import <mach/mach_host.h>
#import <mach/task_info.h>
#import <mach/host_info.h>
#import <mach/task.h>
#import <objc/runtime.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/param.h> 
#include <sys/sysctl.h>
#include <time.h>

NSString *ipForInterface(NSString *interface)
{
    NSString *address = @"N/A";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *tmpaddr = NULL;
    
    if ((getifaddrs(&interfaces)) == 0)
    {
        tmpaddr = interfaces;
        while(tmpaddr != NULL)
        {
            if(tmpaddr->ifa_addr->sa_family == AF_INET)
            {
                if([[NSString stringWithUTF8String:tmpaddr->ifa_name] isEqualToString:interface])
                {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)tmpaddr->ifa_addr)->sin_addr)];
                }
            }
            tmpaddr = tmpaddr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    return address;
}

NSString *getUptime()
{
    int mib [2]; 
    size_t size; 
    time_t now; 
    struct timeval uptime; 
    
    (void)time(&now); 
    
    mib [0] = CTL_KERN; 
    mib [1] = KERN_BOOTTIME; 
    
    size = sizeof(uptime); 
    
    if (sysctl(mib, 2, &uptime, &size, NULL, 0) == 0)
    {
        int seconds = (int)(now - uptime.tv_sec);
        int minutes = (int)(seconds / 60);
        int hours = (int)(minutes / 60);
        
        if (hours >= 1)
        {
            minutes = minutes - (hours * 60); 
        }
        return [NSString stringWithFormat:@"%dh %dmin", hours, minutes];
        
    }
    
    return @"error";
    
}

NSString *getDataIP()
{
    NSString *ip = ipForInterface(@"pdp_ip0");
    
    if (![ip isEqualToString:@"N/A"])
    {
        return ip;
    }
    
    return @"N/A";
}

NSString *getWifiInfo()
{
    NSString *ip = ipForInterface(@"en0");
    NSString *networkName = [[objc_getClass("SBWiFiManager") sharedInstance] currentNetworkName];
    
    if (![ip isEqualToString:@"N/A"] && ![networkName isEqualToString:@""])
    {
        return [NSString stringWithFormat:@"%@ (%@)",networkName,ip];
    }
    
    return @"N/A";
}

NSString *firmwareInfo()
{
    NSString *buildVersion = [[objc_getClass("SBPlatformController") sharedInstance] systemBuildVersion];
    return [NSString stringWithFormat:@"%@ (%@)", [[UIDevice currentDevice] systemVersion], buildVersion];
}



int getFreeMem()
{

    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    //
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) 
    {
        NSLog(@"can't get vm statistics");
        return -1;   
    }
    
    int unit = 1024*1024;
    //int free_mem = (int)((vm_stat.free_count * pagesize) / unit); // RAM *libera* e basta
    int free_plus_inactive_mem = (int)((vm_stat.free_count + vm_stat.inactive_count) * pagesize / unit); // SBSettings ritorna questa
    int total = (int)(((vm_stat.wire_count + vm_stat.active_count + vm_stat.inactive_count + vm_stat.free_count) * pagesize) /unit);
    NSLog(@"%d",total);
    return free_plus_inactive_mem;
}


