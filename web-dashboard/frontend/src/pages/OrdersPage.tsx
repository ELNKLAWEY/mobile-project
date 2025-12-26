import { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import DataTable from '@/components/DataTable';
import ConfirmDialog from '@/components/ConfirmDialog';
import StatusBadge from '@/components/StatusBadge';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { getOrders, updateOrderStatus, deleteOrder, Order } from '@/lib/api';
import {
  MoreHorizontal,
  Eye,
  Trash2,
  Loader2,
  ShoppingCart,
  Package,
  Phone,
  MapPin,
} from 'lucide-react';

const API_BASE = 'https://api.mohamed-osama.cloud';

const getFullImageUrl = (url: string) => {
  if (!url) return '';
  if (url.startsWith('http')) return url;
  return `${API_BASE}${url.startsWith('/') ? '' : '/'}${url}`;
};

const ORDER_STATUSES: Order['status'][] = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];

const OrdersPage = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [statusDialogOpen, setStatusDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [newStatus, setNewStatus] = useState<Order['status']>('pending');
  const { toast } = useToast();

  const fetchOrders = async () => {
    try {
      const data = await getOrders();
      setOrders(data);
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to fetch orders',
        variant: 'destructive',
      });
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  const handleView = (order: Order) => {
    setSelectedOrder(order);
    setViewDialogOpen(true);
  };

  const handleStatusChange = (order: Order) => {
    setSelectedOrder(order);
    setNewStatus(order.status);
    setStatusDialogOpen(true);
  };

  const handleDelete = (order: Order) => {
    setSelectedOrder(order);
    setDeleteDialogOpen(true);
  };

  const submitStatusChange = async () => {
    if (!selectedOrder) return;
    setIsSubmitting(true);
    try {
      await updateOrderStatus(selectedOrder.id, newStatus);
      toast({ title: 'Success', description: 'Order status updated successfully' });
      setStatusDialogOpen(false);
      fetchOrders();
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to update order status',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const confirmDelete = async () => {
    if (!selectedOrder) return;
    setIsSubmitting(true);
    try {
      await deleteOrder(selectedOrder.id);
      toast({ title: 'Success', description: 'Order deleted successfully' });
      setDeleteDialogOpen(false);
      fetchOrders();
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to delete order',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns = [
    { key: 'id', header: 'Order ID', className: 'w-24' },
    {
      key: 'customer',
      header: 'Customer',
      render: (order: Order) => (
        <div>
          <p className="font-medium">{order.user_name || `User #${order.user_id}`}</p>
          <p className="text-sm text-muted-foreground">{order.user_email}</p>
        </div>
      ),
    },
    {
      key: 'items',
      header: 'Items',
      render: (order: Order) => `${order.items.length} item${order.items.length !== 1 ? 's' : ''}`,
    },
    {
      key: 'total_price',
      header: 'Total',
      render: (order: Order) => `$${parseFloat(order.total_price).toFixed(2)}`,
    },
    {
      key: 'status',
      header: 'Status',
      render: (order: Order) => <StatusBadge status={order.status} />,
    },
    {
      key: 'created_at',
      header: 'Date',
      render: (order: Order) => new Date(order.created_at).toLocaleDateString(),
    },
    {
      key: 'actions',
      header: 'Actions',
      className: 'w-16',
      render: (order: Order) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => handleView(order)}>
              <Eye className="h-4 w-4 mr-2" />
              View Details
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => handleStatusChange(order)}>
              <Package className="h-4 w-4 mr-2" />
              Update Status
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              onClick={() => handleDelete(order)}
              className="text-destructive focus:text-destructive"
            >
              <Trash2 className="h-4 w-4 mr-2" />
              Delete
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
    },
  ];

  return (
    <DashboardLayout>
      <div className="space-y-6 animate-fade-in">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <ShoppingCart className="h-6 w-6" />
            Orders
          </h1>
          <p className="text-muted-foreground">Manage and track customer orders</p>
        </div>

        <DataTable
          columns={columns}
          data={orders}
          isLoading={isLoading}
          emptyMessage="No orders found"
          keyExtractor={(order) => order.id}
        />

        {/* View Dialog */}
        <Dialog open={viewDialogOpen} onOpenChange={setViewDialogOpen}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>Order Details</DialogTitle>
              <DialogDescription>Order #{selectedOrder?.id}</DialogDescription>
            </DialogHeader>
            {selectedOrder && (
              <div className="space-y-6">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label className="text-muted-foreground">Customer</Label>
                    <p className="font-medium">{selectedOrder.user_name || `User #${selectedOrder.user_id}`}</p>
                    <p className="text-sm text-muted-foreground">{selectedOrder.user_email}</p>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Status</Label>
                    <div className="mt-1">
                      <StatusBadge status={selectedOrder.status} />
                    </div>
                  </div>
                  <div>
                    <Label className="text-muted-foreground flex items-center gap-1">
                      <Phone className="h-3 w-3" /> Phone
                    </Label>
                    <p className="font-medium">{selectedOrder.user_phone || '-'}</p>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Total</Label>
                    <p className="font-medium text-lg">${parseFloat(selectedOrder.total_price).toFixed(2)}</p>
                  </div>
                  <div className="col-span-2">
                    <Label className="text-muted-foreground flex items-center gap-1">
                      <MapPin className="h-3 w-3" /> Shipping Address
                    </Label>
                    <p className="font-medium">{selectedOrder.user_address || '-'}</p>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Date</Label>
                    <p className="font-medium">{new Date(selectedOrder.created_at).toLocaleString()}</p>
                  </div>
                </div>

                <div>
                  <Label className="text-muted-foreground mb-3 block">Order Items</Label>
                  <div className="space-y-3">
                    {selectedOrder.items.length === 0 ? (
                      <p className="text-center text-muted-foreground py-4">No items in this order</p>
                    ) : (
                      selectedOrder.items.map((item) => (
                        <div
                          key={item.id}
                          className="flex items-center gap-4 p-3 bg-muted/30 rounded-lg"
                        >
                          <div className="w-12 h-12 rounded-lg overflow-hidden bg-muted flex-shrink-0">
                            {item.image ? (
                              <img
                                src={getFullImageUrl(item.image)}
                                alt={item.title}
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  (e.target as HTMLImageElement).style.display = 'none';
                                }}
                              />
                            ) : (
                              <div className="w-full h-full flex items-center justify-center">
                                <Package className="w-5 h-5 text-muted-foreground" />
                              </div>
                            )}
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="font-medium truncate">{item.title}</p>
                            <p className="text-sm text-muted-foreground">
                              Qty: {item.quantity} × ${parseFloat(item.price).toFixed(2)}
                            </p>
                          </div>
                          <div className="text-right">
                            <p className="font-medium">
                              ${(parseFloat(item.price) * item.quantity).toFixed(2)}
                            </p>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              </div>
            )}
          </DialogContent>
        </Dialog>

        {/* Status Change Dialog */}
        <Dialog open={statusDialogOpen} onOpenChange={setStatusDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Update Order Status</DialogTitle>
              <DialogDescription>Change the status of order #{selectedOrder?.id}</DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div className="space-y-2">
                <Label>Current Status</Label>
                <div>
                  <StatusBadge status={selectedOrder?.status || 'pending'} />
                </div>
              </div>
              <div className="space-y-2">
                <Label>New Status</Label>
                <Select value={newStatus} onValueChange={(value) => setNewStatus(value as Order['status'])}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {ORDER_STATUSES.map((status) => (
                      <SelectItem key={status} value={status}>
                        {status.charAt(0).toUpperCase() + status.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setStatusDialogOpen(false)}>
                Cancel
              </Button>
              <Button onClick={submitStatusChange} disabled={isSubmitting}>
                {isSubmitting && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                Update Status
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Delete Confirmation */}
        <ConfirmDialog
          open={deleteDialogOpen}
          onOpenChange={setDeleteDialogOpen}
          title="Delete Order"
          description={`Are you sure you want to delete order #${selectedOrder?.id}? This action cannot be undone.`}
          confirmText="Delete"
          onConfirm={confirmDelete}
          isLoading={isSubmitting}
          variant="destructive"
        />
      </div>
    </DashboardLayout>
  );
};

export default OrdersPage;
