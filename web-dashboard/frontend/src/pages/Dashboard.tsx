import { useEffect, useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import DashboardLayout from '@/components/DashboardLayout';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { getUsers, getProducts, getOrders, User, Product, Order } from '@/lib/api';
import { Users, Package, ShoppingCart, DollarSign, ArrowUpRight, Loader2, TrendingUp } from 'lucide-react';
import StatusBadge from '@/components/StatusBadge';
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  ChartLegend,
  ChartLegendContent,
  type ChartConfig,
} from '@/components/ui/chart';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, ResponsiveContainer } from 'recharts';

const Dashboard = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [usersData, productsData, ordersData] = await Promise.all([
          getUsers(),
          getProducts(),
          getOrders(),
        ]);
        setUsers(usersData);
        setProducts(productsData.products);
        setOrders(ordersData);
      } catch (error) {
        console.error('Failed to fetch dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  const totalRevenue = orders.reduce((sum, order) => sum + parseFloat(order.total_price), 0);
  const pendingOrders = orders.filter((o) => o.status === 'pending').length;

  // Order status chart data
  const orderStatusData = useMemo(() => {
    const statusCounts = orders.reduce((acc, order) => {
      acc[order.status] = (acc[order.status] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    return [
      { name: 'Pending', value: statusCounts['pending'] || 0, fill: 'hsl(var(--warning))' },
      { name: 'Processing', value: statusCounts['processing'] || 0, fill: 'hsl(var(--primary))' },
      { name: 'Shipped', value: statusCounts['shipped'] || 0, fill: 'hsl(var(--info, 200 80% 50%))' },
      { name: 'Delivered', value: statusCounts['delivered'] || 0, fill: 'hsl(var(--success))' },
      { name: 'Cancelled', value: statusCounts['cancelled'] || 0, fill: 'hsl(var(--destructive))' },
    ].filter((item) => item.value > 0);
  }, [orders]);

  // Revenue by recent orders (last 7 orders for simplicity)
  const revenueChartData = useMemo(() => {
    return orders
      .slice(0, 7)
      .reverse()
      .map((order) => ({
        name: `#${order.id}`,
        revenue: parseFloat(order.total_price),
      }));
  }, [orders]);

  const orderStatusConfig: ChartConfig = {
    pending: { label: 'Pending', color: 'hsl(var(--warning))' },
    processing: { label: 'Processing', color: 'hsl(var(--primary))' },
    shipped: { label: 'Shipped', color: 'hsl(200 80% 50%)' },
    delivered: { label: 'Delivered', color: 'hsl(var(--success))' },
    cancelled: { label: 'Cancelled', color: 'hsl(var(--destructive))' },
  };

  const revenueConfig: ChartConfig = {
    revenue: { label: 'Revenue', color: 'hsl(var(--primary))' },
  };

  const stats = [
    {
      title: 'Total Users',
      value: users.length,
      icon: Users,
      link: '/users',
      color: 'text-primary',
      bgColor: 'bg-primary/10',
    },
    {
      title: 'Products',
      value: products.length,
      icon: Package,
      link: '/products',
      color: 'text-success',
      bgColor: 'bg-success/10',
    },
    {
      title: 'Orders',
      value: orders.length,
      icon: ShoppingCart,
      link: '/orders',
      color: 'text-warning',
      bgColor: 'bg-warning/10',
    },
    {
      title: 'Revenue',
      value: `$${totalRevenue.toFixed(2)}`,
      icon: DollarSign,
      link: '/orders',
      color: 'text-primary',
      bgColor: 'bg-primary/10',
    },
  ];

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center h-64">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6 animate-fade-in">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Dashboard</h1>
          <p className="text-muted-foreground">Welcome back! Here's an overview of your store.</p>
        </div>

        {/* Stats Grid */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {stats.map((stat) => (
            <Link key={stat.title} to={stat.link}>
              <Card className="hover:shadow-md transition-shadow cursor-pointer group">
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium text-muted-foreground">
                    {stat.title}
                  </CardTitle>
                  <div className={`p-2 rounded-lg ${stat.bgColor}`}>
                    <stat.icon className={`h-4 w-4 ${stat.color}`} />
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="flex items-center justify-between">
                    <div className="text-2xl font-bold">{stat.value}</div>
                    <ArrowUpRight className="h-4 w-4 text-muted-foreground group-hover:text-primary transition-colors" />
                  </div>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>

        {/* Charts Row */}
        <div className="grid gap-4 md:grid-cols-2">
          {/* Order Status Pie Chart */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <ShoppingCart className="h-5 w-5" />
                Orders by Status
              </CardTitle>
            </CardHeader>
            <CardContent>
              {orderStatusData.length === 0 ? (
                <p className="text-muted-foreground text-center py-8">No orders yet</p>
              ) : (
                <ChartContainer config={orderStatusConfig} className="h-[250px] w-full">
                  <PieChart>
                    <Pie
                      data={orderStatusData}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={90}
                      paddingAngle={2}
                      dataKey="value"
                      nameKey="name"
                      label={({ name, value }) => `${name}: ${value}`}
                      labelLine={false}
                    >
                      {orderStatusData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.fill} />
                      ))}
                    </Pie>
                    <ChartTooltip content={<ChartTooltipContent />} />
                  </PieChart>
                </ChartContainer>
              )}
            </CardContent>
          </Card>

          {/* Revenue Bar Chart */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="h-5 w-5" />
                Recent Orders Revenue
              </CardTitle>
            </CardHeader>
            <CardContent>
              {revenueChartData.length === 0 ? (
                <p className="text-muted-foreground text-center py-8">No orders yet</p>
              ) : (
                <ChartContainer config={revenueConfig} className="h-[250px] w-full">
                  <BarChart data={revenueChartData}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis
                      dataKey="name"
                      tickLine={false}
                      axisLine={false}
                      tickMargin={8}
                    />
                    <YAxis
                      tickLine={false}
                      axisLine={false}
                      tickMargin={8}
                      tickFormatter={(value) => `$${value}`}
                    />
                    <ChartTooltip
                      content={<ChartTooltipContent />}
                      formatter={(value) => [`$${value}`, 'Revenue']}
                    />
                    <Bar
                      dataKey="revenue"
                      fill="hsl(var(--primary))"
                      radius={[4, 4, 0, 0]}
                    />
                  </BarChart>
                </ChartContainer>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Recent Orders */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>Recent Orders</CardTitle>
            <Link
              to="/orders"
              className="text-sm text-primary hover:underline flex items-center gap-1"
            >
              View all <ArrowUpRight className="h-3 w-3" />
            </Link>
          </CardHeader>
          <CardContent>
            {orders.length === 0 ? (
              <p className="text-muted-foreground text-center py-8">No orders yet</p>
            ) : (
              <div className="space-y-4">
                {orders.slice(0, 5).map((order) => (
                  <div
                    key={order.id}
                    className="flex items-center justify-between p-4 rounded-lg bg-muted/30"
                  >
                    <div>
                      <p className="font-medium">Order #{order.id}</p>
                      <p className="text-sm text-muted-foreground">
                        {order.user_name || `User #${order.user_id}`}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="font-medium">${parseFloat(order.total_price).toFixed(2)}</p>
                      <StatusBadge status={order.status} />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Pending Orders Alert */}
        {pendingOrders > 0 && (
          <Card className="border-warning/50 bg-warning/5">
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-warning/10">
                  <ShoppingCart className="h-5 w-5 text-warning" />
                </div>
                <div>
                  <p className="font-medium">
                    You have {pendingOrders} pending order{pendingOrders > 1 ? 's' : ''}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    Review and process them to keep your customers happy.
                  </p>
                </div>
                <Link to="/orders" className="ml-auto">
                  <span className="text-primary hover:underline text-sm font-medium">
                    View orders →
                  </span>
                </Link>
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </DashboardLayout>
  );
};

export default Dashboard;
